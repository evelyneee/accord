//
//  ServerListView+Mentions.swift
//  ServerListView+Mentions
//
//  Created by evelyn on 2021-09-01.
//

import Foundation

extension ServerListView: MentionSenderDelegate {
    func addMention(guild: String, channel: String) {
        if guild == "@me" {
            guard channel != String(self.selection ?? 0) else { print("currently reading already"); return }
            guard let index = Self.privateChannels.generateKeyMap()[channel] else { return }
            Self.privateChannels[index].read_state?.mention_count += 1
        }
        guard channel != String(self.selection ?? 0) else { print("currently reading already"); return }
        let index = Self.folders.map { ServerListView.fastIndexGuild(guild, array: $0.guilds) }
        for (i, v) in index.enumerated() {
            guard let v = v, var folderList = Self.folders[i].guilds[v].channels else { continue }
            folderList.append(contentsOf: Self.privateChannels)
            if let index = fastIndexChannels(channel, array: folderList) {
                Self.folders[i].guilds[v].channels?[index].read_state?.mention_count += 1
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Updater"), object: nil, userInfo: [:])
            viewUpdater.updateView()
        }
    }

    func deselect() {
        selection = nil
    }

    func removeMentions(server: String) {
        let index = Self.folders.map { ServerListView.fastIndexGuild(server, array: $0.guilds) }
        for (index1, index2) in index.enumerated() {
            guard let index2 = index2 else { return }
            Self.folders[index1].guilds[index2].channels?.forEach { $0.read_state?.mention_count = 0 }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Updater"), object: nil, userInfo: [:])
            viewUpdater.updateView()
        }
    }

    func select(channel: Channel) {
        let guildID = channel.guild_id ?? "@me"
        if guildID == "@me" {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DMSelect"), object: nil, userInfo: ["index": channel.id])
        }
        let index = Self.folders.map { ServerListView.fastIndexGuild(guildID, array: $0.guilds) }
        print(index)
        for (i, v) in index.enumerated() {
            guard let v = v else { continue }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Refresh"), object: nil, userInfo: [Self.folders[i].guilds[v].index ?? 0: Int(channel.id) ?? 0])
        }
    }
    
    func newMessage(in channelID: String, with messageID: String, isDM: Bool) {
        newMessageProcessThread.async {
            if isDM {
                guard let index = ServerListView.privateChannels.generateKeyMap()[channelID] else { return }
                ServerListView.privateChannels[index].last_message_id = messageID
            } else {
                guard channelID != String(self.selection ?? 0) else { print("currently reading already"); return }
                ServerListView.folders.enumerated().forEach { index1, folder in
                    folder.guilds.enumerated().forEach { index2, guild in
                        guild.channels?.enumerated().forEach { index3, channel in
                            if channel.id == channelID {
                                let messagesWereRead = channel.last_message_id == channel.read_state?.last_message_id
                                ServerListView.folders[index1].guilds[index2].channels?[index3].last_message_id = messageID
                                if messagesWereRead {
                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Updater"), object: nil, userInfo: [:])
                                        viewUpdater.updateView()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

let newMessageProcessThread = DispatchQueue(label: "NewMessageProcessor")

//
//  ServerListView+Mentions.swift
//  ServerListView+Mentions
//
//  Created by evelyn on 2021-09-01.
//

import Foundation
import UserNotifications

extension ServerListView: MentionSenderDelegate {
    func addMention(guild: String, channel: String) {
        if guild == "@me" {
            guard channel != String(selection ?? 0) else { print("currently reading already"); return }
            guard let index = appModel.privateChannels.generateKeyMap()[channel] else { return }
            DispatchQueue.main.async {
                appModel.privateChannels[index].read_state?.mention_count? += 1
            }
        }
        guard channel != String(selection ?? 0) else { print("currently reading already"); return }
        let index = appModel.folders.map { ServerListView.fastIndexGuild(guild, array: $0.guilds) }
        for (i, v) in index.enumerated() {
            guard let v = v else { continue }
            var folderList = appModel.folders[i].guilds[v].channels
            folderList.append(contentsOf: appModel.privateChannels)
            if let index = fastIndexChannels(channel, array: folderList) {
                DispatchQueue.main.async {
                    appModel.folders[i].guilds[v].channels[index].read_state?.mention_count? += 1
                }
            }
        }
        DispatchQueue.main.async {
            self.appModel.objectWillChange.send()
        }
    }

    func deselect() {
        selection = nil
    }

    func removeMentions(server: String) {
        let index = appModel.folders.map { $0.guilds[indexOf: server] }
        for (index1, index2) in index.enumerated().filter({ $0.element != nil }) {
            DispatchQueue.main.async {
                appModel.folders[index1].guilds[index2!].channels.forEach { $0.read_state?.mention_count = 0 }
            }
        }
    }

    func select(channel: Channel) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: channel.guild_id == nil ? "DMSelect" : "Refresh"), object: nil, userInfo: [channel.guild_id ?? "index": channel.guild_id == nil ? channel.id : Int(channel.id) ?? 0])
    }

    func newMessage(in channelID: String, message: Message) {
        let messageID = message.id
        let isDM = message.guildID == nil
        let guildID = message.guildID ?? "@me"
        newMessageProcessThread.async {
            let ids = message.mentions.map(\.id)
            if ids.contains(user_id) || (appModel.privateChannels.map(\.id).contains(channelID) && message.author?.id != user_id) {
                let matchingGuild = Array(appModel.folders.map(\.guilds).joined())[keyed: message.guildID ?? ""]
                let matchingChannel = matchingGuild?.channels[keyed: message.channelID] ?? appModel.privateChannels[keyed: message.channelID]
                showNotification(
                    title: message.author?.username ?? "Unknown User",
                    subtitle: matchingGuild == nil ? matchingChannel?.computedName ?? "Direct Messages" : "#\(matchingChannel?.computedName ?? "") • \(matchingGuild?.name ?? "")",
                    description: message.content,
                    pfpURL: pfpURL(message.author?.id, message.author?.avatar, "128"),
                    id: message.channelID
                )
                self.addMention(guild: guildID, channel: channelID)
            }
            if isDM {
                guard let index = appModel.privateChannels.generateKeyMap()[channelID] else { return }
                DispatchQueue.main.async {
                    self.appModel.privateChannels[index].last_message_id = messageID
                }
            } else {
                guard channelID != String(self.selection ?? 0) else { print("currently reading already"); return }
                appModel.folders.enumerated().forEach { index1, folder in
                    folder.guilds.enumerated().forEach { index2, guild in
                        guild.channels.enumerated().forEach { index3, channel in
                            if channel.id == channelID {
                                DispatchQueue.main.async {
                                    appModel.folders[index1].guilds[index2].channels[index3].last_message_id = messageID
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

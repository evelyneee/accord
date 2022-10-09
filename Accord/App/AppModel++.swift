//
//  self++.swift
//  Accord
//
//  Created by evelyn on 2022-09-15.
//

import Foundation

extension AppGlobals {
    func addMention(guild: String, channel: String) {
        if guild == "@me" {
            guard channel != selectedChannel?.id else { print("currently reading already"); return }
            guard let index = self.privateChannels.generateKeyMap()[channel] else { return }
            DispatchQueue.main.async {
                self.privateChannels[index].read_state?.mention_count? += 1
            }
        }
        guard channel != selectedChannel?.id else { print("currently reading already"); return }
        let index = self.folders.map { ServerListView.fastIndexGuild(guild, array: $0.guilds) }
        for (i, v) in index.enumerated() {
            guard let v = v else { continue }
            var folderList = self.folders[i].guilds[v].channels
            folderList.append(contentsOf: self.privateChannels)
//            if let index = fastIndexChannels(channel, array: folderList) {
//                DispatchQueue.main.async {
//                    self.folders[i].guilds[v].channels[index].read_state?.mention_count? += 1
//                }
//            }
        }
        DispatchQueue.main.async {
            self.self.objectWillChange.send()
        }
    }

    func deselect() {
        selectedChannel = nil
    }

    func removeMentions(server: String) {
        let index = self.folders.map { $0.guilds[indexOf: server] }
        for (index1, index2) in index.enumerated().filter({ $0.element != nil }) {
            DispatchQueue.main.async {
                self.folders[index1].guilds[index2!].channels.forEach { $0.read_state?.mention_count = 0 }
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
        DispatchQueue.global().async {
            let ids = message.mentions.map(\.id)
            if ids.contains(user_id) || (self.privateChannels.map(\.id).contains(channelID) && message.author?.id != user_id) {
                let matchingGuild = Array(self.folders.map(\.guilds).joined())[keyed: message.guildID ?? ""]
                let matchingChannel = matchingGuild?.channels[keyed: message.channelID] ?? self.privateChannels[keyed: message.channelID]
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
                guard let index = self.privateChannels.generateKeyMap()[channelID] else { return }
                DispatchQueue.main.async {
                    self.self.privateChannels[index].last_message_id = messageID
                }
            } else {
                guard channelID != self.selectedChannel?.id else { print("currently reading already"); return }
                self.folders.enumerated().forEach { index1, folder in
                    folder.guilds.enumerated().forEach { index2, guild in
                        guild.channels.enumerated().forEach { index3, channel in
                            if channel.id == channelID {
                                DispatchQueue.main.async {
                                    self.folders[index1].guilds[index2].channels[index3].last_message_id = messageID
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

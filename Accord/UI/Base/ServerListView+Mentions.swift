//
//  ServerListView+Mentions.swift
//  ServerListView+Mentions
//
//  Created by evelyn on 2021-09-01.
//

import Foundation

extension ServerListView: MentionSenderDelegate {
    func addMention(guild: String, channel: String) {
        let index = Self.folders.map { ServerListView.fastIndexGuild(guild, array: $0.guilds) }
        for (i, v) in index.enumerated() {
            guard let v = v, var folderList = Self.folders[i].guilds[v].channels else { continue }
            folderList.append(contentsOf: Self.privateChannels)
            if let index = fastIndexChannels(channel, array: folderList) {
                Self.folders[i].guilds[v].channels?[index].read_state?.mention_count += 1
            }
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
    }

    func sendWSError(error _: Error) {
        print("bad")
        online = false
    }

    func select(channel: Channel) {
        let guildID = channel.guild_id ?? "@me"
        if guildID == "@me" {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DMSelect"), object: nil, userInfo: ["index": channel.id])
        }
        print("selecting")
        let index = Self.folders.map { ServerListView.fastIndexGuild(guildID, array: $0.guilds) }
        print(index)
        for (i, v) in index.enumerated() {
            guard let v = v else { continue }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Refresh"), object: nil, userInfo: [Self.folders[i].guilds[v].index ?? 0: Int(channel.id) ?? 0])
        }
    }

    // This does not work unfortunately, needs some work
    /*
     func fastBindReadState(channels: [Channel], read_state: [ReadStateEntry]) -> [Channel] {
         let dict =  Dictionary(uniqueKeysWithValues: zip(channels, read_state))
         return dict.map { (element) -> (Channel) in
             element.key.read_state = element.value
             return element.key
         }
     }
     */
}

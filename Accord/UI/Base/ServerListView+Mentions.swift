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
            print("joe mama")
            guard let v = v else { continue }
            if let index = self.fastIndexChannels(channel, array: Self.folders[i].guilds[v].channels ?? []) {
                print("cock")
                Self.folders[i].guilds[v].channels?[index].read_state?.mention_count += 1
            }
        }
    }
    func deselect() {
        selection = nil
    }
    func removeMentions(server: String) {
        let index = Self.folders.compactMap { ServerListView.fastIndexGuild(server, array: $0.guilds) }
        for (index1, index2) in index.enumerated() {
            let guild = Self.folders[index1].guilds[index2]
            guild.channels?.forEach { $0.read_state?.mention_count = 0 }
        }
    }

    func sendWSError(error: Error) {
        print("bad")
        self.online = false
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

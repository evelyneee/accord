//
//  ServerListView+Mentions.swift
//  ServerListView+Mentions
//
//  Created by evelyn on 2021-09-01.
//

import Foundation

extension ServerListView: MentionSenderDelegate {
    func addMention(guild: String, channel: String) {
        let index = folders.map { ServerListView.fastIndexGuild(guild, array: $0.guilds) }
        for (i, v) in index.enumerated() {
            print("joe mama")
            guard let v = v else { continue }
            if let index = self.fastIndexChannels(channel, array: folders[i].guilds[v].channels ?? []) {
                print("cock")
                folders[i].guilds[v].channels?[index].read_state?.mention_count += 1
            }
        }
    }
    func deselect() {
        selection = nil
    }
    func removeMentions(server: String) {
        guard let guild = ServerListView.fastIndexGuild(server, array: guilds) else { return }
        for channel in (guilds)[guild].channels! {
            channel.read_state?.mention_count = 0
        }
    }
    
    func sendWSError(error: Error) {
        print("bad")
        self.online = false
    }
    
    /// This does not work unfortunately, needs some work
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


//
//  ServerListView+Mentions.swift
//  ServerListView+Mentions
//
//  Created by evelyn on 2021-09-01.
//

import Foundation

extension ServerListView: MentionSenderDelegate {
    func addMention(guild: String, channel: String) {
        guard let index = ServerListView.fastIndexGuild(guild, array: self.guilds) else { return }
        let _guild = guilds[index]
        if let index = self.fastIndexChannels(channel, array: _guild.channels ?? []), let _channel = _guild.channels?[index] {
            _channel.read_state?.mention_count++
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


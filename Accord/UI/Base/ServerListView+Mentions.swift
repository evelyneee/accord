//
//  ServerListView+Mentions.swift
//  ServerListView+Mentions
//
//  Created by evelyn on 2021-09-01.
//

import Foundation

extension ServerListView: MentionSenderDelegate {
    func addMention(guild: String, channel: String) {
        for i in guilds ?? [] {
            if i.id == guild {
                for i in i.channels! {
                    if i.id == channel {
                        i.read_state?.mention_count += 1
                        break
                    }
                }
            }
        }
    }
    func deselect() {
        selection = nil
    }
    func removeMentions(server: String) {
        guard let guild = fastIndexGuild(server, array: guilds ?? []) else { return }
        for channel in (guilds ?? [])[guild].channels! {
            channel.read_state?.mention_count = 0
        }
    }
}

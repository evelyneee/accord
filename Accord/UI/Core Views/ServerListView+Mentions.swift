//
//  ServerListView+Mentions.swift
//  ServerListView+Mentions
//
//  Created by evelyn on 2021-09-01.
//

import Foundation

extension ServerListView: MentionSenderDelegate {
    func addMention(guild: String, channel: String) {
        for i in guilds {
            print("balls")
            if i.id == guild {
                print("ok")
                for i in i.channels! {
                    if i.id == channel {
                        print("ok")
                        i.read_state?.mention_count += 1
                        break
                    }
                }
            }
        }
    }
}

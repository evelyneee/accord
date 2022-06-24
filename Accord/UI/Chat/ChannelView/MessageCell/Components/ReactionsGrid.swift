//
//  ReactionsGrid.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct ReactionsGridView: View {
    
    @Environment(\.channelID)
    var channelID: String

    var messageID: String
    @State var reactions: [Reaction]

    var body: some View {
        GridStack($reactions, rowAlignment: .leading, columns: 6, content: { reaction in
            ReactionView(messageID: messageID, reaction: reaction)
        })
        .fixedSize()
    }
}

struct ReactionView: View {
    
    @Environment(\.channelID)
    var channelID: String
    
    var messageID: String
    
    @State var reaction: Reaction
    @State var me: Bool = false
    
    var body: some View {
        Button(action: {
            print("troll")
            var emoji = (reaction.emoji.name ?? "null")
            if let id = reaction.emoji.id {
                emoji.append(":" + (id))
            }
            let url = root
                .appendingPathComponent("channels")
                .appendingPathComponent(channelID)
                .appendingPathComponent("messages")
                .appendingPathComponent(messageID)
                .appendingPathComponent("reactions")
                .appendingPathComponent(emoji)
                .appendingPathComponent("@me")
                .appendingQueryParameters([
                    "location":"Message"
                ])
            print(url)
            Request.ping(url: url, headers: Headers(
                token: Globals.token,
                type: reaction.me ? .DELETE : .PUT,
                discordHeaders: true,
                referer: "https://discord.com/channels/@me"
            ))
            reaction.me.toggle()
            if reaction.me { reaction.count -= 1 } else { reaction.count += 1 }
        }) {
            GroupBox {
                HStack {
                    if let id = reaction.emoji.id {
                        Attachment(cdnURL + "/emojis/\(id).png?size=16")
                            .equatable()
                            .frame(width: 16, height: 16)
                    } else if let name = reaction.emoji.name {
                        Text(name)
                            .frame(width: 16, height: 16)
                    }
                    Text(String(reaction.count))
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(reaction.me ? .blue : nil)
        }
        .buttonStyle(.borderless)
        .padding(4)
        .id((reaction.emoji.id ?? "") + (reaction.emoji.name ?? ""))
    }
}

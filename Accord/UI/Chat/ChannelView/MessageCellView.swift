//
//  MessageCellView.swift
//  Accord
//
//  Created by evelyn on 2021-12-12.
//

import Foundation
import SwiftUI
import AppKit
import Combine

struct MessageCellView: View {
    var message: Message
    var nick: String?
    var replyNick: String?
    var pronouns: String?
    var avatar: String?
    var guildID: String?
    @Binding var role: String?
    @Binding var replyRole: String?
    @Binding var replyingTo: Message?
    @State var popup: Bool = false
    @State var textElement: Text?
    @State var bag = Set<AnyCancellable>()
    var body: some View {
        VStack(alignment: .leading) {
            if let reply = message.referenced_message {
                HStack { [unowned reply] in
                    Attachment(pfpURL(reply.author?.id, reply.author?.avatar, "16")).equatable()
                        .frame(width: 15, height: 15)
                        .clipShape(Circle())
                    Text(replyNick ?? reply.author?.username ?? "")
                        .foregroundColor(replyRole != nil && roleColors[replyRole!]?.0 != nil && !message.isSameAuthor ? Color(int: roleColors[replyRole!]!.0) : Color(NSColor.textColor))
                        .fontWeight(.semibold)
                    if #available(macOS 12.0, *) {
                        Text(try! AttributedString(markdown: reply.content))
                            .lineLimit(0)
                    } else {
                        Text(reply.content)
                            .lineLimit(0)
                    }
                }
                .padding(.leading, 47)
            }
            HStack { [unowned message] in
                if !(message.isSameAuthor && message.referenced_message == nil) {
                    Attachment(avatar != nil ? "https://cdn.discordapp.com/guilds/\(guildID ?? "")/users/\(message.author?.id ?? "")/avatars/\(avatar!).png?size=48" : pfpURL(message.author?.id, message.author?.avatar)).equatable()
                        .frame(width: 33, height: 33)
                        .clipShape(Circle())
                        .highPriorityGesture(TapGesture())
                        .onTapGesture {
                            popup.toggle()
                        }
                }
                
                VStack(alignment: .leading) {
                    if message.isSameAuthor && message.referenced_message == nil {
                        AsyncMarkdown(message.content)
                            .padding(.leading, 41)
                    } else {
                        Text(nick ?? message.author?.username ?? "Unknown User")
                            .foregroundColor(role != nil && roleColors[role!]?.0 != nil && !message.isSameAuthor ? Color(int: roleColors[role!]!.0) : Color(NSColor.textColor))
                            .fontWeight(.semibold)
                        +
                        Text("  \(message.timestamp.makeProperDate())")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                        +
                        Text(message.edited_timestamp != nil ? " (edited at \(message.edited_timestamp?.makeProperHour() ?? "unknown time"))" : "")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                        +
                        Text((pronouns != nil) ? " • \(pronouns ?? "Use my name")" : "")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                        AsyncMarkdown(message.content)
                    }
                }
                Spacer()
            }

            HStack {
                ForEach(message.reactions ?? [], id: \.emoji.id) { reaction in
                    HStack(spacing: 4) {
                        Attachment("https://cdn.discordapp.com/emojis/\(reaction.emoji.id ?? "").png?size=16")
                            .frame(width: 16, height: 16)
                        Text(String(reaction.count))
                            .fontWeight(Font.Weight.medium)
                    }
                    .padding(4)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(4)
                    .padding(.leading, 41)
                }
            }
            ForEach(message.embeds ?? [], id: \.hashValue) { embed in
                EmbedView(embed: embed).equatable()
                    .padding(.leading, 41)
            }
            ForEach(message.sticker_items ?? [], id: \.id) { sticker in
                Attachment("https://media.discordapp.net/stickers/\(sticker.id).png?size=160")
                    .frame(width: 160, height: 160)
                    .cornerRadius(3)
                    .padding(.leading, 41)
            }
            AttachmentView(media: message.attachments)
                .padding(.leading, 41)
                .padding(.top, 5)
        }
        .id(message.id)
    }
}

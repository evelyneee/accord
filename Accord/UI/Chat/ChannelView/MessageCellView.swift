//
//  MessageCellView.swift
//  Accord
//
//  Created by evelyn on 2021-12-12.
//

import AppKit
import Combine
import Foundation
import SwiftUI

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
    @Binding var editing: String?
    @State var popup: Bool = false
    @State var textElement: Text?
    @State var bag = Set<AnyCancellable>()
    
    @State var editedText: String = ""
    
    @AppStorage("GifProfilePictures") var gifPfp: Bool = false
    
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
                if !(message.isSameAuthor && message.referenced_message == nil && message.author?.avatar != nil) {
                    if let author = message.author, let avatar = author.avatar, gifPfp && message.author?.avatar?.prefix(2) == "a_" {
                        HoverGifView.init(url: "https://cdn.discordapp.com/avatars/\(author.id)/\(avatar).gif?size=48")
                            .frame(width: 33, height: 33)
                            .clipShape(Circle())
                            .popover(isPresented: $popup, content: {
                                PopoverProfileView(user: message.author)
                            })
                    } else {
                        Attachment(avatar != nil ? "https://cdn.discordapp.com/guilds/\(guildID ?? "")/users/\(message.author?.id ?? "")/avatars/\(avatar!).png?size=48" : pfpURL(message.author?.id, message.author?.avatar)).equatable()
                            .frame(width: 33, height: 33)
                            .clipShape(Circle())
                            .popover(isPresented: $popup, content: {
                                PopoverProfileView(user: message.author)
                            })
                    }

                }
                VStack(alignment: .leading) {
                    if message.isSameAuthor, message.referenced_message == nil {
                        if let editingID = self.editing, editingID == message.id {
                            TextField("Edit your message", text: self.$editedText, onEditingChanged: { _ in }) {
                                Request.ping(url: URL(string: "\(rootURL)/channels/\(message.channel_id)/messages/\(editingID)"), headers: Headers(
                                    userAgent: discordUserAgent,
                                    token: AccordCoreVars.token,
                                    bodyObject: ["content":editedText],
                                    type: .PATCH,
                                    discordHeaders: true,
                                    json: true
                                ))
                                self.editing = nil
                                self.editedText = ""
                            }
                            .textFieldStyle(SquareBorderTextFieldStyle())
                            .onAppear {
                                self.editedText = message.content
                            }
                            .padding(.leading, 41)
                        } else {
                            AsyncMarkdown(message.content)
                                .padding(.leading, 41)
                        }
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
                        if let editingID = self.editing, editingID == message.id {
                            TextField("Edit your message", text: self.$editedText, onEditingChanged: { _ in }) {
                                Request.ping(url: URL(string: "\(rootURL)/channels/\(message.channel_id)/messages/\(editingID)"), headers: Headers(
                                    userAgent: discordUserAgent,
                                    token: AccordCoreVars.token,
                                    bodyObject: ["content":editedText],
                                    type: .PATCH,
                                    discordHeaders: true,
                                    json: true
                                ))
                                self.editing = nil
                                self.editedText = ""
                            }
                            .textFieldStyle(SquareBorderTextFieldStyle())
                            .onAppear {
                                self.editedText = message.content
                            }
                        } else {
                            AsyncMarkdown(message.content)
                        }
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
        .contextMenu {
            Button("Reply") { [weak message] in
                replyingTo = message
            }
            Button("Edit") { [weak message] in
                self.editing = message?.id
            }
            Button("Delete") { [weak message] in
                message?.delete()
            }
            Button("Copy") { [weak message] in
                guard let content = message?.content else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(content, forType: .string)
            }
            Button("Copy Message Link") { [weak message] in
                guard let channelID = message?.channel_id, let id = message?.id else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("https://discord.com/channels/\(message?.guild_id ?? "@me")/\(channelID)/\(id)", forType: .string)
            }
            Button("Show profile") {
                popup.toggle()
            }
        }
        .id(message.id)
    }
}

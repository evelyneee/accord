//
//  MessageCellView.swift
//  Accord
//
//  Created by evelyn on 2021-12-12.
//

import AppKit
import AVKit
import Combine
import Foundation
import SwiftUI

struct MessageCellView: View, Equatable {
    static func == (lhs: MessageCellView, rhs: MessageCellView) -> Bool {
        lhs.message == rhs.message && lhs.nick == rhs.nick && lhs.avatar == rhs.avatar
    }

    var message: Message
    var nick: String?
    var replyNick: String?
    var pronouns: String?
    var avatar: String?
    var guildID: String?
    @Binding var role: String?
    @Binding var replyRole: String?
    @Binding var replyingTo: Message?
    @State var editing: Bool = false
    @State var popup: Bool = false
    @State var textElement: Text?
    @State var bag = Set<AnyCancellable>()
    @State var editedText: String = ""

    @AppStorage("GifProfilePictures")
    var gifPfp: Bool = false

    var editingTextField: some View {
        TextField("Edit your message", text: self.$editedText, onEditingChanged: { _ in }) {
            message.edit(now: self.editedText)
            self.editing = false
            self.editedText = ""
        }
        .textFieldStyle(SquareBorderTextFieldStyle())
        .onAppear {
            self.editedText = message.content
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let reply = message.referenced_message {
                HStack(alignment: .bottom) { [unowned reply] in
                    Attachment(pfpURL(reply.author?.id, reply.author?.avatar, discriminator: reply.author?.discriminator ?? "0005", "16"))
                        .equatable()
                        .frame(width: 15, height: 15)
                        .clipShape(Circle())
                    Text(replyNick ?? reply.author?.username ?? "")
                        .font(.subheadline)
                        .foregroundColor({ () -> Color in
                            if let replyRole = replyRole, let color = roleColors[replyRole]?.0, !message.isSameAuthor {
                                return Color(int: color)
                            }
                            return Color.primary
                        }())
                        .fontWeight(.semibold)
                    if #available(macOS 12.0, *) {
                        Text(try! AttributedString(markdown: reply.content))
                            .font(.subheadline)
                            .lineLimit(0)
                            .foregroundColor(.secondary)
                    } else {
                        Text(reply.content)
                            .font(.subheadline)
                            .lineLimit(0)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 47)
            }
            if let interaction = message.interaction {
                HStack { [unowned interaction] in
                    Attachment(pfpURL(interaction.user?.id, interaction.user?.avatar, "16"))
                        .equatable()
                        .frame(width: 15, height: 15)
                        .clipShape(Circle())
                    Text(interaction.user?.username ?? "")
                        .font(.subheadline)
                        .foregroundColor({ () -> Color in
                            if let replyRole = replyRole, let color = roleColors[replyRole]?.0, !message.isSameAuthor {
                                return Color(int: color)
                            }
                            return Color.primary
                        }())
                        .fontWeight(.semibold)
                    Text("/" + interaction.name)
                        .font(.subheadline)
                        .lineLimit(0)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 47)
            }
            HStack(alignment: .top) { [unowned message] in
                if !(message.isSameAuthor && message.referenced_message == nil) {
                    Attachment(avatar != nil ? cdnURL + "/guilds/\(guildID ?? "")/users/\(message.author?.id ?? "")/avatars/\(avatar!).png?size=48" : pfpURL(message.author?.id, message.author?.avatar, discriminator: message.author?.discriminator ?? "0005"))
                        .equatable()
                        .frame(width: 33, height: 33)
                        .clipShape(Circle())
                        .popover(isPresented: $popup, content: {
                            PopoverProfileView(user: message.author)
                        })
                }
                VStack(alignment: .leading) {
                    if message.isSameAuthor, message.referenced_message == nil {
                        if self.editing {
                            editingTextField
                                .padding(.leading, 41)
                        } else {
                            AsyncMarkdown(message.content, font: message.content.hasEmojisOnly)
                                .equatable()
                                .padding(.leading, 41)
                        }
                    } else {
                        HStack(spacing: 1) {
                            Text(nick ?? message.author?.username ?? "Unknown User")
                                .foregroundColor({ () -> Color in
                                    if let role = role, let color = roleColors[role]?.0, !message.isSameAuthor {
                                        return Color(int: color)
                                    }
                                    return Color.primary
                                }())
                                .font(.chatTextFont)
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
                            if message.author?.bot ?? false {
                                Text("Bot")
                                    .padding(.horizontal, 4)
                                    .foregroundColor(Color.white)
                                    .font(.subheadline)
                                    .background(Capsule().fill().foregroundColor(Color.red))
                                    .padding(.horizontal, 4)
                            }
                            if message.author?.system ?? false {
                                Text("System")
                                    .padding(.horizontal, 4)
                                    .foregroundColor(Color.white)
                                    .font(.subheadline)
                                    .background(Capsule().fill().foregroundColor(Color.purple))
                                    .padding(.horizontal, 4)
                            }
                        }
                        if self.editing {
                            editingTextField
                        } else {
                            AsyncMarkdown(message.content, font: message.content.hasEmojisOnly)
                                .equatable()
                        }
                    }
                }
                Spacer()
            }
            LazyVGrid.init(columns: Array.init(repeating: GridItem(.flexible(minimum: 45, maximum: 55), spacing: 4), count: 4), alignment: .leading, spacing: 4, content: {
                ForEach(message.reactions ?? [], id: \.identifier) { reaction in
                    HStack(spacing: 4) {
                        if let id = reaction.emoji.id {
                            Attachment(cdnURL + "/emojis/\(id).png?size=16")
                                .equatable()
                                .frame(width: 16, height: 16)
                        } else if let name = reaction.emoji.name {
                            Text(name)
                                .frame(width: 16, height: 16)
                        }
                        Text(String(reaction.count))
                            .fontWeight(Font.Weight.medium)
                    }
                    .padding(4)
                    .frame(minWidth: 45, maxWidth: 55)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(4)
                }
            })
            .padding(.leading, 41)
            ForEach(message.embeds ?? [], id: \.id) { embed in
                EmbedView(embed: embed)
                    .equatable()
                    .padding(.leading, 41)
            }
            ForEach(message.sticker_items ?? [], id: \.id) { sticker in
                Attachment("https://media.discordapp.net/stickers/\(sticker.id).png?size=160")
                    .equatable()
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
            Button("Edit") {
                self.editing.toggle()
            }.disabled(message.author?.id != AccordCoreVars.user?.id)
            Button("Delete") { [weak message] in
                DispatchQueue.global().async {
                    message?.delete()
                }
            }.disabled(message.author?.id != AccordCoreVars.user?.id)
            Divider()
            Button("Show profile") {
                popup.toggle()
            }
            Divider()
            Menu("Copy") {
                Button("Copy message text") { [weak message] in
                    guard let content = message?.content else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                }
                Button("Copy message link") { [weak message] in
                    guard let channelID = message?.channel_id, let id = message?.id else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("https://discord.com/channels/\(message?.guild_id ?? guildID ?? "@me")/\(channelID)/\(id)", forType: .string)
                }
                Button("Copy user ID") { [weak message] in
                    guard let id = message?.author?.id else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(id, forType: .string)
                }
                Button("Copy message ID") { [weak message] in
                    guard let id = message?.id else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(id, forType: .string)
                }
                Button("Copy username and tag", action: { [weak message] in
                    guard let author = message?.author else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("\(author.username)#\(author.discriminator)", forType: .string)
                })
                Button("Copy image of message", action: {
                    self.imageRepresentation { image in
                        if let image = image {
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.writeObjects([image])
                        }
                    }
                })
            }
            if !message.attachments.isEmpty {
                Divider()
                ForEach(message.attachments, id: \.url) { attachment in
                    Menu(attachment.filename) { [weak attachment] in
                        if attachment?.isFile == false {
                            Button("Open in window") {
                                guard let attachment = attachment else { return }
                                if attachment.isVideo, let url = URL(string: attachment.url) {
                                    attachmentWindows(
                                        player: AVPlayer(url: url),
                                        url: nil,
                                        name: attachment.filename,
                                        width: attachment.width ?? 500,
                                        height: attachment.height ?? 500
                                    )
                                } else if attachment.isImage {
                                    attachmentWindows(
                                        player: nil,
                                        url: attachment.url,
                                        name: attachment.filename,
                                        width: attachment.width ?? 500,
                                        height: attachment.height ?? 500
                                    )
                                }
                            }
                        }
                        if let stringURL = attachment?.url, let url = URL(string: stringURL) {
                            Button("Open URL in browser") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        Button("Copy image URL") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(attachment?.url ?? "", forType: .string)
                        }
                    }
                }
            }
        }
        .id(message.id)
    }
}

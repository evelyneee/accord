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

struct GridStack<T: Identifiable, Content: View>: View {
    let rows: Int?
    let columns: Int?
    let verticalAlignment: SwiftUI.HorizontalAlignment
    let horizontalAlignment: SwiftUI.VerticalAlignment
    let array: [T]
    let content: (T) -> Content

    @ViewBuilder
    var body: some View {
        if let rows = rows {
            VStack(alignment: self.verticalAlignment) {
                ForEach(0 ..< rows, id: \.self) { row in
                    HStack(alignment: self.horizontalAlignment) {
                        ForEach(0 ..< Int(round(Double(array.count / rows))), id: \.self) { column in
                            content(self.array[row*column])
                                .id(self.array[row*column].id)
                                .onAppear { print(self.array[row*column].id) }
                        }
                    }
                    .id(UUID())
                }
            }
        } else if let columns = columns {
            VStack(alignment: self.verticalAlignment) {
                ForEach(0 ..< Int(round(Double(array.count / columns))), id: \.self) { row in
                    HStack(alignment: self.horizontalAlignment) {
                        ForEach(0 ..< columns, id: \.self) { column in
                            content(self.array[row*column])
                                .id(self.array[row*column].id)
                                .onAppear { print(self.array[row*column].id) }
                        }
                        .id(UUID())
                    }
                }
                .id(UUID())
            }
        }
    }

    init(_ array: [T], rowAlignment: SwiftUI.HorizontalAlignment = .center, columnAlignment: SwiftUI.VerticalAlignment = .center, rows: Int? = nil, columns: Int? = nil, @ViewBuilder content: @escaping (T) -> Content) {
        self.array = array
        self.verticalAlignment = rowAlignment
        self.horizontalAlignment = columnAlignment
        self.rows = rows
        self.columns = columns
        self.content = content
    }
}

fileprivate var encoder: ISO8601DateFormatter = {
    let encoder = ISO8601DateFormatter()
    encoder.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return encoder
}()

struct MessageCellView: View, Equatable {
    static func == (lhs: MessageCellView, rhs: MessageCellView) -> Bool {
        lhs.message == rhs.message && lhs.nick == rhs.nick && lhs.avatar == rhs.avatar
    }

    var message: Message
    var nick: String?
    var replyNick: String?
    var pronouns: String?
    var avatar: String?
    var guildID: String
    var permissions: Permissions
    @Binding var role: String?
    @Binding var replyRole: String?
    @Binding var replyingTo: Message?
    @State var editing: Bool = false
    @State var popup: Bool = false
    @State var editedText: String = ""

    @AppStorage("GifProfilePictures")
    var gifPfp: Bool = false
    
    private let leftPadding: CGFloat = 45

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

    func timeout(time: String) {
        let url = URL(string: "https://discord.com/api/v9/guilds/")?
            .appendingPathComponent(guildID)
            .appendingPathComponent("members")
            .appendingPathComponent(message.author!.id)
        DispatchQueue.global().async {
            Request.ping(url: url, headers: Headers(
                userAgent: discordUserAgent,
                token: AccordCoreVars.token,
                bodyObject: ["communication_disabled_until":time],
                type: .PATCH,
                discordHeaders: true,
                referer: "https://discord.com/channels/\(guildID)/\(self.message.channel_id)",
                json: true
            ))
        }
    }
    
    @ViewBuilder
    private var reactionsGrid: some View {
        if let reactions = message.reactions {
            GridStack(reactions, rowAlignment: .leading, columns: 6, content: { reaction in
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
                        .fontWeight(.medium)
                }
                .padding(4)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(4)
            })
            .padding(.leading, leftPadding)
        }
    }
    
    private var stickerView: some View {
        ForEach(message.sticker_items ?? [], id: \.id) { sticker in
            if sticker.format_type == .lottie {
                GifView("https://cdn.discordapp.com/stickers/\(sticker.id).json")
                    .frame(width: 160, height: 160)
                    .cornerRadius(3)
                    .padding(.leading, leftPadding)
            } else {
                Attachment("https://media.discordapp.net/stickers/\(sticker.id).png?size=160")
                    .equatable()
                    .frame(width: 160, height: 160)
                    .cornerRadius(3)
                    .padding(.leading, leftPadding)
            }
        }
    }
    
    private var authorText: some View {
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
            Text("  \(message.processedTimestamp ?? "")")
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
            if message.author?.bot == true {
                Text("Bot")
                    .padding(.horizontal, 4)
                    .foregroundColor(Color.white)
                    .font(.subheadline)
                    .background(Capsule().fill().foregroundColor(Color.red))
                    .padding(.horizontal, 4)
            }
            if message.author?.system == true {
                Text("System")
                    .padding(.horizontal, 4)
                    .foregroundColor(Color.white)
                    .font(.subheadline)
                    .background(Capsule().fill().foregroundColor(Color.purple))
                    .padding(.horizontal, 4)
           }
        }

    }
    
    private var copyMenu: some View {
        Menu("Copy") {
            Button("Copy message text") { [weak message] in
                guard let content = message?.content else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(content, forType: .string)
            }
            Button("Copy message link") { [weak message] in
                guard let channelID = message?.channel_id, let id = message?.id else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("https://discord.com/channels/\(message?.guild_id ?? guildID)/\(channelID)/\(id)", forType: .string)
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

    }
    
    private var moderationMenu: some View {
        Menu("Moderation") {
            if permissions.contains(.banMembers) {
                Button("Ban") {
                    let url = URL(string: rootURL)?
                        .appendingPathComponent("guilds")
                        .appendingPathComponent(guildID)
                        .appendingPathComponent("bans")
                        .appendingPathComponent(message.author!.id)
                    DispatchQueue.global().async {
                        Request.ping(url: url, headers: Headers(
                            userAgent: discordUserAgent,
                            token: AccordCoreVars.token,
                            bodyObject: ["delete_message_days":1],
                            type: .PUT,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/\(guildID)/\(self.message.channel_id)"
                        ))
                    }
                }
            }
            if permissions.contains(.kickMembers) {
                Button("Kick") {
                    let url = URL(string: rootURL)?
                        .appendingPathComponent("guilds")
                        .appendingPathComponent(guildID)
                        .appendingPathComponent("members")
                        .appendingPathComponent(message.author!.id)
                    DispatchQueue.global().async {
                        Request.ping(url: url, headers: Headers(
                            userAgent: discordUserAgent,
                            token: AccordCoreVars.token,
                            type: .DELETE,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/\(guildID)/\(self.message.channel_id)"
                        ))
                    }
                }
            }
            if permissions.contains(.moderateMembers) {
                Menu("Timeout") {
                    Button("60 seconds") {
                        let date = Date() + 60
                        let encoded = encoder.string(from: date)
                        self.timeout(time: encoded)
                    }
                    Button("5 minutes") {
                        let date = Date() + 60 * 5
                        let encoded = encoder.string(from: date)
                        self.timeout(time: encoded)
                    }
                    Button("10 minutes") {
                        let date = Date() + 60 * 10
                        let encoded = encoder.string(from: date)
                        self.timeout(time: encoded)
                    }
                    Button("1 hour") {
                        let date = Date() + 60 * 60
                        let encoded = encoder.string(from: date)
                        self.timeout(time: encoded)
                    }
                    Button("1 day") {
                        let date = Date() + 60 * 60 * 24
                        let encoded = encoder.string(from: date)
                        self.timeout(time: encoded)
                    }
                    Button("1 week") {
                        let date = Date() + 60 * 60 * 24 * 7
                        let encoded = encoder.string(from: date)
                        self.timeout(time: encoded)
                    }
                }
            }
        }
    }
    
    private var attachmentMenu: some View {
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
                Button("Copy media URL") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(attachment?.url ?? "", forType: .string)
                }
            }
        }
    }
    
    @ViewBuilder
    private var contextMenuContent: some View {
        Button("Reply") { [weak message] in
            replyingTo = message
        }
        if message.author?.id == AccordCoreVars.user?.id {
            Button("Edit") {
                self.editing.toggle()
            }
        }
        if message.author?.id == AccordCoreVars.user?.id || self.permissions.contains(.manageMessages) {
            Button("Delete") { [weak message] in
                DispatchQueue.global().async {
                    message?.delete()
                }
            }
        }
        Divider()
        Button("Show profile") {
            popup.toggle()
        }
        Divider()
        copyMenu
        if !message.attachments.isEmpty {
            Divider()
            attachmentMenu
        }
        moderationSection
    }
    
    @ViewBuilder
    private var moderationSection: some View {
        if self.guildID == "@me" || (self.guildID != "@me" && permissions.moderator) {
            Divider()
        }
        if self.permissions.contains(.manageMessages) || guildID == "@me" {
            Button(message.pinned == false ? "Pin" : "Unpin") {
                let url = URL(string: rootURL)?
                    .appendingPathComponent("channels")
                    .appendingPathComponent(message.channel_id)
                    .appendingPathComponent("pins")
                    .appendingPathComponent(message.id)
                DispatchQueue.global().async {
                    Request.ping(url: url, headers: Headers(
                        userAgent: discordUserAgent,
                        token: AccordCoreVars.token,
                        type: message.pinned == false ? .PUT : .DELETE,
                        discordHeaders: true,
                        referer: "https://discord.com/channels/\(guildID)/\(self.message.channel_id)"
                    ))
                    DispatchQueue.main.async {
                        message.pinned?.toggle()
                    }
                }
            }
        }
        if message.author != nil &&
            guildID != "@me" &&
            permissions.moderator {
                moderationMenu
        } else if self.guildID == "@me" && permissions.contains(.kickMembers) {
            Button("Remove member") {
                let url = URL(string: rootURL)?
                    .appendingPathComponent("channels")
                    .appendingPathComponent(self.message.channel_id)
                    .appendingPathComponent("recipients")
                    .appendingPathComponent(message.author!.id)
                DispatchQueue.global().async {
                    Request.ping(url: url, headers: Headers(
                        userAgent: discordUserAgent,
                        token: AccordCoreVars.token,
                        type: .DELETE,
                        discordHeaders: true,
                        referer: "https://discord.com/channels/@me/\(self.message.channel_id)"
                    ))
                }
            }
        }
    }
    
    private var replyView: some View {
        HStack {
            RoundedRectangle(cornerRadius: 5)
                .trim(from: 0.5, to: 0.75)
                .stroke(.gray.opacity(0.4), lineWidth: 2)
                .frame(width: 53, height: 20)
                .padding(.bottom, -15)
                .padding(.trailing, -30)
            Attachment(pfpURL(message.referenced_message?.author?.id, message.referenced_message?.author?.avatar, discriminator: message.referenced_message?.author?.discriminator ?? "0005", "16"))
                .equatable()
                .frame(width: 15, height: 15)
                .clipShape(Circle())
            Text(replyNick ?? message.referenced_message?.author?.username ?? "")
                .font(.subheadline)
                .foregroundColor({ () -> Color in
                    if let replyRole = replyRole, let color = roleColors[replyRole]?.0, !message.isSameAuthor {
                        return Color(int: color)
                    }
                    return Color.primary
                }())
                .fontWeight(.semibold)
            Text(message.referenced_message?.content ?? "Error")
                .font(.subheadline)
                .lineLimit(0)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, -3)
        .padding(.leading, 15)
    }
    
    private var interactionView: some View {
        HStack {
            Attachment(pfpURL(message.interaction?.user?.id, message.interaction?.user?.avatar, "16"))
                .equatable()
                .frame(width: 15, height: 15)
                .clipShape(Circle())
            Text(message.interaction?.user?.username ?? "")
                .font(.subheadline)
                .foregroundColor({ () -> Color in
                    if let replyRole = replyRole, let color = roleColors[replyRole]?.0, !message.isSameAuthor {
                        return Color(int: color)
                    }
                    return Color.primary
                }())
                .fontWeight(.semibold)
            Text("/" + (message.interaction?.name ?? ""))
                .font(.subheadline)
                .lineLimit(0)
                .foregroundColor(.secondary)
        }
        .padding(.leading, 47)
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if let author = message.author {
            if (self.avatar?.prefix(2) ?? author.avatar?.prefix(2)) == "a_" {
                GifView({ () -> String in
                    if let avatar = self.avatar {
                        return cdnURL + "/guilds/\(guildID)/users/\(author.id)/avatars/\(avatar).gif?size=48"
                    } else {
                        return cdnURL + "/avatars/\(author.id)/\(author.avatar!).gif?size=48"
                    }
                }())
            } else {
                Attachment ({ () -> String in
                    if let avatar = self.avatar {
                        return cdnURL + "/guilds/\(guildID)/users/\(author.id)/avatars/\(avatar).png?size=48"
                    } else if let avatar = author.avatar {
                        return cdnURL + "/avatars/\(author.id)/\(avatar).png?size=48"
                    } else {
                        let index = String((Int(author.discriminator) ?? 0) % 5)
                        return cdnURL + "/embed/avatars/\(index).png"
                    }
                }())
                .equatable()
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if message.referenced_message != nil {
                replyView
            }
            if message.interaction != nil {
                interactionView
            }
            switch message.type {
            case .recipientAdd:
                Label(title: {
                    Text(message.author?.username ?? "Unknown User").fontWeight(.semibold)
                    + Text(" added ")
                    + Text(message.mentions.first??.username ?? "Unknown User").fontWeight(.semibold)
                    + Text(" to the group")
                }, icon: {
                    Image(systemName: "arrow.forward").foregroundColor(.green)
                })
                .padding(.leading, leftPadding)
            case .recipientRemove:
                Label(title: {
                    Text(message.author?.username ?? "Unknown User").fontWeight(.semibold)
                    + Text(" left the group")
                }, icon: {
                    Image(systemName: "arrow.backward").foregroundColor(.red)
                })
                .padding(.leading, leftPadding)
            case .channelNameChange:
                Label(title: {
                    Text(message.author?.username ?? "Unknown User").fontWeight(.semibold)
                    + Text(" changed the channel name")
                }, icon: {
                    Image(systemName: "pencil")
                })
                .padding(.leading, leftPadding)
            case .guildMemberJoin:
                Label(title: {
                    (Text("Welcome, ")
                     + Text(message.author?.username ?? "Unknown User").fontWeight(.semibold)
                    + Text("!"))
                }, icon: {
                    Image(systemName: "arrow.forward").foregroundColor(.green)
                })
                .padding(.leading, leftPadding)
            default:
                HStack(alignment: .top) { [unowned message] in
                    if !(message.isSameAuthor && message.referenced_message == nil) {
                        avatarView
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                            .popover(isPresented: $popup, content: {
                                PopoverProfileView(user: message.author, guildID: self.guildID)
                            })
                            .padding(.trailing, 1.5)
                    }
                    VStack(alignment: .leading) {
                        if message.isSameAuthor, message.referenced_message == nil {
                            if !message.content.isEmpty {
                                if self.editing {
                                    editingTextField
                                        .padding(.leading, leftPadding)
                                } else {
                                    AsyncMarkdown(message.content)
                                        .equatable()
                                        .padding(.leading, leftPadding)
                                }
                            } else {
                                Spacer().frame(height: 2)
                            }
                        } else {
                            authorText
                            Spacer().frame(height: 1.3)
                            if !message.content.isEmpty {
                                if self.editing {
                                    editingTextField
                                } else {
                                    AsyncMarkdown(message.content)
                                        .equatable()
                                }
                            }
                        }
                    }
                    Spacer()
                }

            }
            if message.sticker_items?.isEmpty == false {
                stickerView
            }
            ForEach(message.embeds ?? [], id: \.id) { embed in
                EmbedView(embed: embed)
                    .equatable()
                    .padding(.leading, leftPadding)
            }
            if !message.attachments.isEmpty {
                AttachmentView(media: message.attachments)
                    .padding(.leading, leftPadding)
                    .padding(.top, 5)
            }
            if message.reactions?.isEmpty == false {
                reactionsGrid
            }
        }
        .contextMenu { contextMenuContent }
        .id(message.id)
    }
}

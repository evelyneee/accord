//
//  MessageCellMenu.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import AVKit
import SwiftUI

private var encoder: ISO8601DateFormatter = {
    let encoder = ISO8601DateFormatter()
    encoder.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return encoder
}()

struct MessageCellMenu: View {
    @State var message: Message
    
    
    @Environment(\.guildID)
    var guildID: String
    
    var permissions: Permissions
    @Binding var replyingTo: Message?
    @Binding var editing: Bool
    @Binding var popup: Bool
    @Binding var showEditNicknamePopover: Bool
    @Binding var reactionPopup: Bool

    @ViewBuilder
    private var moderationSection: some View {
        if self.guildID == "@me" || (self.guildID != "@me" && permissions.moderator) {
            Divider()
        }
        if self.permissions.contains(.manageMessages) || guildID == "@me" {
            Button(message.pinned == false ? "Pin" : "Unpin") {
                let url = URL(string: rootURL)?
                    .appendingPathComponent("channels")
                    .appendingPathComponent(message.channelID)
                    .appendingPathComponent("pins")
                    .appendingPathComponent(message.id)
                DispatchQueue.global().async {
                    Request.ping(url: url, headers: Headers(
                        token: Globals.token,
                        type: message.pinned == false ? .PUT : .DELETE,
                        discordHeaders: true,
                        referer: "https://discord.com/channels/\(guildID)/\(self.message.channelID)"
                    ))
                    DispatchQueue.main.async {
                        message.pinned?.toggle()
                    }
                }
            }
        }
        if message.author != nil,
           guildID != "@me",
           permissions.moderator
        {
            moderationMenu
        } else if self.guildID == "@me", permissions.contains(.kickMembers) {
            Button("Remove member") {
                let url = URL(string: rootURL)?
                    .appendingPathComponent("channels")
                    .appendingPathComponent(self.message.channelID)
                    .appendingPathComponent("recipients")
                    .appendingPathComponent(message.author!.id)
                DispatchQueue.global().async {
                    Request.ping(url: url, headers: Headers(
                        token: Globals.token,
                        type: .DELETE,
                        discordHeaders: true,
                        referer: "https://discord.com/channels/@me/\(self.message.channelID)"
                    ))
                }
            }
        }
    }

    func timeout(time: String) {
        let url = URL(string: "https://discord.com/api/v9/guilds/")?
            .appendingPathComponent(guildID)
            .appendingPathComponent("members")
            .appendingPathComponent(message.author!.id)
        DispatchQueue.global().async {
            Request.ping(url: url, headers: Headers(
                token: Globals.token,
                bodyObject: ["communication_disabled_until": time],
                type: .PATCH,
                discordHeaders: true,
                referer: "https://discord.com/channels/\(guildID)/\(self.message.channelID)",
                json: true
            ))
        }
    }

    private var copyMenu: some View {
        Menu("Copy") {
            Button("Copy message text") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.content, forType: .string)
            }
            Button("Copy message link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("https://discord.com/channels/\(message.guildID ?? guildID)/\(message.channelID)/\(message.id)", forType: .string)
            }
            Button("Copy user ID") {
                guard let id = message.author?.id else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(id, forType: .string)
            }
            Button("Copy message ID") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.id, forType: .string)
            }
            Button("Copy username and tag", action: {
                guard let author = message.author else { return }
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
                            token: Globals.token,
                            bodyObject: ["delete_message_days": 1],
                            type: .PUT,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/\(guildID)/\(self.message.channelID)"
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
                            token: Globals.token,
                            type: .DELETE,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/\(guildID)/\(self.message.channelID)"
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

    var body: some View {
        Group {
            Button("Reply") {
                replyingTo = message
            }
            if self.permissions.contains(.addReactions) {
                Button("Add Reaction") {
                    self.reactionPopup.toggle()
                }
            }
            if message.author?.id == Globals.user?.id {
                Button("Edit") {
                    self.editing.toggle()
                }
            }
            if message.author?.id == Globals.user?.id || self.permissions.contains(.manageMessages) {
                Button("Delete") {
                    DispatchQueue.global().async {
                        message.delete()
                    }
                }
            }
        }
        Divider()
        Button("Show profile") {
            popup.toggle()
        }

        if (message.author == Globals.user) || self.permissions.contains(.manageNicknames), guildID != "@me" {
            Button("Set nickname") {
                showEditNicknamePopover.toggle()
            }
        }

        Divider()
        copyMenu
        if !message.attachments.isEmpty {
            Divider()
            attachmentMenu
        }
        moderationSection
    }
}

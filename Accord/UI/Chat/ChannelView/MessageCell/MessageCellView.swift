//
//  MessageCellView.swift
//  Accord
//
//  Created by evelyn on 2021-12-12.
//

import AVKit
import SwiftUI

struct MessageCellView: View, Equatable {
    static func == (lhs: MessageCellView, rhs: MessageCellView) -> Bool {
        lhs.message.id == rhs.message.id && lhs.nick == rhs.nick && lhs.avatar == rhs.avatar
    }

    @Binding var message: Message
    
    @Binding var nick: String?
    @Binding var replyNick: String?
    @Binding var pronouns: String?
    @Binding var avatar: String?
    
    @Environment(\.channelID)
    var channelID: String
    
    @Environment(\.guildID)
    var guildID: String
    
    @Binding var permissions: Permissions
    @Binding var role: String?
    @Binding var replyRole: String?
    
    @MainActor @Binding
    var replyingTo: Message?
    
    @State var editing: Bool = false
    @State var popup: Bool = false
    @State var editedText: String = ""
    @State var showEditNicknamePopover: Bool = false
    @State var reactionPopup: Bool = false

    @AppStorage("GifProfilePictures")
    var gifPfp: Bool = false

    private let leftPadding: Double = 44.5

    @EnvironmentObject
    var appModel: AppGlobals
    
    var editingTextField: some View {
        TextField("Edit your message", text: self.$editedText, onEditingChanged: { _ in }) {
            let text = self.editedText
            DispatchQueue.global().async {
                message.edit(now: text)
            }
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
            if let reply = message.referencedMessage {
                ReplyView (
                    reply: reply,
                    replyNick: replyNick,
                    replyRole: $replyRole
                )
            }
            if let interaction = message.interaction {
                InteractionView(
                    interaction: interaction,
                    isSameAuthor: message.isSameAuthor,
                    replyRole: self.$replyRole
                )
                .padding(.leading, 47)
            }
            switch message.type {
            case .recipientAdd:
                RecipientAddView (
                    message: self.message
                )
                .padding(.leading, leftPadding)
            case .recipientRemove:
                if let user = message.author {
                    RecipientRemoveView (
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            case .channelNameChange:
                if let user = message.author {
                    ChannelNameChangeView (
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            case .guildMemberJoin:
                if let user = message.author {
                    WelcomeMessageView (
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            case .channelMessagePin:
                if let user = message.author {
                    MessagePinView(
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            case .userBoostedServer:
                if let user = message.author {
                    ServerBoostView(
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            case .guildReachedLevelOne:
                ServerLevelUpView(level: 1)
                    .padding(.leading, leftPadding)
            case .guildReachedLevelTwo:
                ServerLevelUpView(level: 2)
                    .padding(.leading, leftPadding)
            case .guildReachedLevelThree:
                ServerLevelUpView(level: 3)
                    .padding(.leading, leftPadding)
            case .call:
                if let user = message.author {
                    CallView(
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            default:
                HStack(alignment: .top) {
                    if let author = message.author, !(message.isSameAuthor && message.referencedMessage == nil && message.inSameDay) {
                        AvatarView (
                            author: author,
                            avatar: self.avatar,
                            popup: self.$popup
                        )
                        .equatable()
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                        .padding(.trailing, 1.5)
                    }
                    VStack(alignment: .leading) {
                        if message.isSameAuthor && message.referencedMessage == nil && message.inSameDay {
                            if !message.content.isEmpty {
                                if self.editing {
                                    editingTextField
                                        .font(.chatTextFont)
                                        .padding(.leading, leftPadding)
                                } else {
                                    AsyncMarkdown(message.content)
                                        .equatable()
                                        .padding(.leading, leftPadding)
                                        .popover(isPresented: $popup, content: {
                                            PopoverProfileView(user: message.author)
                                        })
                                }
                            }
                        } else {
                            AuthorTextView(
                                message: self.message,
                                pronouns: self.pronouns,
                                nick: self.$nick,
                                role: self.$role
                            )
                            .equatable()
                            Spacer().frame(height: 1.3)
                            if !message.content.isEmpty {
                                if self.editing {
                                    editingTextField
                                        .font(.chatTextFont)
                                } else {
                                    AsyncMarkdown(message.content)
                                        .equatable()
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .if(Storage.users[self.message.author?.id ?? ""]?.relationship?.type == .blocked, transform: { $0.hidden() })
            }
            if let stickerItems = message.stickerItems, !stickerItems.isEmpty {
                StickerView(
                    stickerItems: stickerItems
                )
            }
            if !message.embeds.isEmpty {
                ForEach($message.embeds, id: \.id) { embed in
                    EmbedView(embed: embed)
                        .equatable()
                        .padding(.leading, leftPadding)
                }
            }
            if !message.attachments.isEmpty {
                AttachmentView(media: message.attachments)
                    .background(
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(5)
                            ProgressView()
                        }
                    )
                    .cornerRadius(5)
                    .padding(.leading, leftPadding)
                    .padding(.top, 5)
            }
            if !message.reactions.isEmpty {
                ReactionsGridView (
                    message: $message
                )
                .padding(.leading, leftPadding)
            }
        }
        .contextMenu {
            MessageCellMenu(
                message: self.message,
                permissions: self.permissions,
                replyingTo: self.$replyingTo,
                editing: self.$editing,
                popup: self.$popup,
                showEditNicknamePopover: self.$showEditNicknamePopover,
                reactionPopup: self.$reactionPopup
            )
        }
        .popover(isPresented: $showEditNicknamePopover) {
            SetNicknameView(user: message.author, isPresented: $showEditNicknamePopover)
                .padding()
        }
        .popover(isPresented: self.$reactionPopup, content: {
            EmotesView(onSelect: { emote in
                self.reactionPopup = false
                let emoji = emote.name + ":" + emote.id
                let url = root
                    .appendingPathComponent("channels")
                    .appendingPathComponent(channelID)
                    .appendingPathComponent("messages")
                    .appendingPathComponent(self.message.id)
                    .appendingPathComponent("reactions")
                    .appendingPathComponent(emoji)
                    .appendingPathComponent("@me")
                    .appendingQueryParameters([
                        "location":"Message"
                    ])
                Request.ping(url: url, headers: Headers(
                    token: Globals.token,
                    type: .PUT,
                    discordHeaders: true,
                    referer: "https://discord.com/channels/@me"
                ))
                self.message._reactions?.append(Reaction(count: 1, me: true, emoji: .init(id: emote.id, name: emote.name, animated: emote.animated)))
            })
        })
    }
}

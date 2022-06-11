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
        lhs.message == rhs.message && lhs.nick == rhs.nick && lhs.avatar == rhs.avatar
    }

    var message: Message
    var nick: String?
    var replyNick: String?
    var pronouns: String?
    var avatar: String?
    var guildID: String
    @Binding var permissions: Permissions
    @Binding var role: String?
    @Binding var replyRole: String?
    @Binding var replyingTo: Message?
    @State var editing: Bool = false
    @State var popup: Bool = false
    @State var editedText: String = ""
    @State var showEditNicknamePopover: Bool = false

    @AppStorage("GifProfilePictures")
    var gifPfp: Bool = false

    private let leftPadding: CGFloat = 44.5

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
                ReplyView(
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
                RecipientAddView(
                    message: self.message
                )
                .padding(.leading, leftPadding)
            case .recipientRemove:
                if let user = message.author {
                    RecipientRemoveView(
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            case .channelNameChange:
                if let user = message.author {
                    ChannelNameChangeView(
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            case .guildMemberJoin:
                if let user = message.author {
                    WelcomeMessageView(
                        user: user
                    )
                    .padding(.leading, leftPadding)
                }
            default:
                HStack(alignment: .top) {
                    if let author = message.author, !(message.isSameAuthor && message.referenced_message == nil) {
                        AvatarView(
                            author: author,
                            guildID: self.guildID,
                            avatar: self.avatar
                        )
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                        .popover(isPresented: $popup, content: {
                            PopoverProfileView(user: message.author, guildID: self.guildID)
                        })
                        .padding(.trailing, 1.5)
                        .fixedSize()
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
                                        .popover(isPresented: $popup, content: {
                                            PopoverProfileView(user: message.author, guildID: self.guildID)
                                        })
                                }
                            } else {
                                Spacer().frame(height: 2)
                            }
                        } else {
                            AuthorTextView(
                                message: self.message,
                                pronouns: self.pronouns,
                                nick: self.nick,
                                role: self.$role
                            )
                            .fixedSize()
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
            if let stickerItems = message.sticker_items,
               stickerItems.isEmpty == false
            {
                StickerView(
                    stickerItems: stickerItems
                )
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
                    .fixedSize()
            }
            if let reactions = message.reactions, !reactions.isEmpty {
                ReactionsGridView(
                    reactions: reactions
                )
                .padding(.leading, leftPadding)
            }
        }
        .contextMenu {
            MessageCellMenu(
                message: self.message,
                guildID: self.guildID,
                permissions: self.permissions,
                replyingTo: self.$replyingTo,
                editing: self.$editing,
                popup: self.$popup,
                showEditNicknamePopover: self.$showEditNicknamePopover
            )
        }
        .popover(isPresented: $showEditNicknamePopover) {
            SetNicknameView(user: message.author, guildID: self.guildID, isPresented: $showEditNicknamePopover)
                .padding()
        }
    }
}

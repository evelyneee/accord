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
    
    @Environment(\.channelID)
    var channelID: String
    
    @Environment(\.guildID)
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

    @EnvironmentObject
    var appModel: AppGlobals
    
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
            default:
                HStack(alignment: .top) {
                    if let author = message.author, !(message.isSameAuthor && message.referencedMessage == nil && message.inSameDay) {
                        AvatarView (
                            author: author,
                            avatar: self.avatar
                        )
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                        .popover(isPresented: $popup, content: {
                            PopoverProfileView(user: message.author)
                        })
                        .padding(.trailing, 1.5)
                        .fixedSize()
                    }
                    VStack(alignment: .leading) {
                        if message.isSameAuthor && message.referencedMessage == nil && message.inSameDay {
                            if !message.content.isEmpty {
                                if self.editing {
                                    editingTextField
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
            if let stickerItems = message.stickerItems,
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
                    .background {
                        Rectangle()
                            .foregroundColor(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(5)
                        ProgressView()
                    }
                    .cornerRadius(5)
                    .padding(.leading, leftPadding)
                    .padding(.top, 5)
                    .fixedSize()
            }
            if let reactions = message.reactions, !reactions.isEmpty {
                ReactionsGridView (
                    messageID: self.message.id,
                    reactions: reactions
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
                showEditNicknamePopover: self.$showEditNicknamePopover
            )
        }
        .popover(isPresented: $showEditNicknamePopover) {
            SetNicknameView(user: message.author, isPresented: $showEditNicknamePopover)
                .padding()
        }
    }
}

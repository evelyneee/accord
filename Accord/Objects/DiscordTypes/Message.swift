//
//  Message.swift
//  Message
//
//  Created by evelyn on 2021-08-16.
//

import AppKit
import Foundation

struct Message: Codable, Equatable, Identifiable, Hashable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content && lhs.embeds == rhs.embeds
    }

    var author: User?
    var nick: String?
    var channelID: String
    var guildID: String?
    var content: String
    var editedTimestamp: Date?
    var id: String
    var embeds: [Embed]?
    var mentionEveryone: Bool?
    var mentions: [User]
    var user_mentioned: Bool?

    var userMentioned: Bool { user_mentioned ?? false }
    var bottomInset: CGFloat {
        (isSameAuthor && referencedMessage == nil ? 0.5 : 13.0) - (userMentioned ? 3.0 : 0.0)
    }

    var pinned: Bool?
    var timestamp: Date
    var processedTimestamp: String?
    var _inSameDay: Bool?
    var inSameDay: Bool { self._inSameDay ?? true }
    var type: MessageType
    var attachments: [AttachedFiles]
    var referencedMessage: Reply?
    // var message_reference: Reply? // in the mentions endpoint
    let stickerItems: [StickerItem]?
    var reactions: [Reaction]?
    var interaction: Interaction?

    enum CodingKeys: String, CodingKey {
        case author, nick, content, id, embeds,
             mentions, pinned, timestamp, processedTimestamp,
             _inSameDay, type, attachments, reactions, interaction,
            user_mentioned
        case channelID = "channel_id"
        case guildID = "guild_id"
        case editedTimestamp = "edited_timestamp"
        case mentionEveryone = "mention_everyone"
        case referencedMessage = "referenced_message"
        case stickerItems = "sticker_items"
    }
    
    var identifier: String {
        content + id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func delete() {
        let headers = Headers(
            contentType: nil,
            token: Globals.token,
            type: .DELETE,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID ?? "@me")/\(channelID)",
            empty: true
        )
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(id)"), headers: headers)
    }

    func edit(now: String) {
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(id)"), headers: Headers(
            token: Globals.token,
            bodyObject: ["content": now],
            type: .PATCH,
            discordHeaders: true,
            json: true
        ))
    }

    var sameAuthor: Bool?
    var isSameAuthor: Bool { sameAuthor ?? false }
}

final class Reply: Codable, Equatable, Identifiable, Hashable {
    static func == (lhs: Reply, rhs: Reply) -> Bool {
        lhs.id == rhs.id
    }

    var author: User?
    var channel_id: String
    var guild_id: String?
    var content: String
    var edited_timestamps: Bool?
    var id: String
    var mention_everyone: Bool?
    var mentions: [User?]
    var nonce: Int?
    var pinned: Bool?
    var timestamp: String
    var tts: Bool
    var type: MessageType
    var attachments: [AttachedFiles]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum MessageType: Int, Codable {
    case `default` = 0, recipientAdd, recipientRemove, call,
         channelNameChange, channelIconChange, channelMessagePin,
         guildMemberJoin, userBoostedServer, guildReachedLevelOne,
         guildReachedLevelTwo, guildReachedLevelThree, unused,
         channelFollowAdd, guildDiscoveryDisqualified,
         guildDiscoveryRequalified, guildDiscoveryGracePeriodInitialWarning,
         guildDiscoveryGracePeriodFinalWarning, threadCreated, reply,
         chatInputCommand, threadStarterMessage, guildInviteReminder,
         contextMenuCommand, likelyScammer
}

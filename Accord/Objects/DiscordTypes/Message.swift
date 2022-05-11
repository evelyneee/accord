//
//  Message.swift
//  Message
//
//  Created by evelyn on 2021-08-16.
//

import AppKit
import Foundation

final class Message: Decodable, Equatable, Identifiable, Hashable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content
    }

    var author: User?
    var nick: String?
    var channel_id: String
    var guild_id: String?
    var content: String
    var edited_timestamp: Date?
    var id: String
    var embeds: [Embed]?
    var mention_everyone: Bool?
    var mentions: [User?]
    var user_mentioned: Bool?
    var pinned: Bool?
    var timestamp: Date
    var processedTimestamp: String?
    var type: MessageType
    var attachments: [AttachedFiles]
    var referenced_message: Reply?
    // var message_reference: Reply? // in the mentions endpoint
    let sticker_items: [StickerItem]?
    var reactions: [Reaction]?
    var interaction: Interaction?

    var identifier: String {
        content + id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func delete() {
        let headers = Headers(
            userAgent: discordUserAgent,
            contentType: nil,
            token: AccordCoreVars.token,
            type: .DELETE,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guild_id ?? "")/\(channel_id)",
            empty: true
        )
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channel_id)/messages/\(id)"), headers: headers)
    }

    func edit(now: String) {
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channel_id)/messages/\(id)"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
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

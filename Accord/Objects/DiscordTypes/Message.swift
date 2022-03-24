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
    var edited_timestamp: String?
    var id: String
    var embeds: [Embed]?
    var mention_everyone: Bool?
    var mentions: [User?]
    var nonce: String?
    var pinned: Bool?
    var timestamp: Date
    var tts: Bool
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
        Request.ping(url: URL(string: "\(rootURL)/channels/\(self.channel_id)/messages/\(self.id)"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            bodyObject: ["content":now],
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
    case `default`, recipientAdd, recipientRemove, `call`,
    channelNameChange, channelIconChange, channelMessagePin,
    guildMemberJoin, userBoostedServer, guildReachedLevelOne,
    guildReachedLevelTwo, guildReachedLevelThree, unused,
    channelFollowAdd, guildDiscoveryDisqualified,
    guildDiscoveryRequalified, guildDiscoveryGracePeriodInitialWarning,
    guildDiscoveryGracePeriodFinalWarning, threadCreated, reply,
    chatInputCommand, threadStarterMessage, guildInviteReminder,
    contextMenuCommand, likelyScammer
}

// TODO: Component object

/*
 [
   {
     "type": 1,
     "components": [
       {
         "type": 2,
         "style": 5,
         "emoji": {
           "name": "apple_music",
           "id": "847868738870968380"
         },
         "url": "https://geo.music.apple.com/us/album/_/1489214567?i=1489214627&mt=1&app=music&ls=1&at=1000lHKX"
       },
       {
         "type": 2,
         "style": 5,
         "emoji": {
           "name": "soundcloud",
           "id": "847868739257106453"
         },
         "url": "https://soundcloud.com/voltra/iso-beam"
       },
       {
         "type": 2,
         "style": 5,
         "emoji": {
           "name": "spotify",
           "id": "847868739298131998"
         },
         "url": "https://open.spotify.com/track/1KcSxfoaa2zrxMUIez9QiI"
       }
     ]
   },
   {
     "type": 1,
     "components": [
       {
         "type": 2,
         "style": 5,
         "emoji": {
           "name": "tidal",
           "id": "847868738254012467"
         },
         "url": "https://listen.tidal.com/track/123567071"
       },
       {
         "type": 2,
         "style": 5,
         "emoji": {
           "name": "youtube",
           "id": "847883855344042044"
         },
         "url": "https://www.youtube.com/watch?v=-kKeL2vMcUY"
       },
       {
         "type": 2,
         "style": 5,
         "emoji": {
           "name": "youtube_music",
           "id": "847868739172827156"
         },
         "url": "https://music.youtube.com/watch?v=-kKeL2vMcUY"
       }
     ]
   }
 ]
 */

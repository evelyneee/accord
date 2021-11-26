//
//  Message.swift
//  Message
//
//  Created by evelyn on 2021-08-16.
//

import Foundation
import AppKit

final class Message: Decodable, Equatable, Identifiable, Hashable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
        
    var author: User?
    var nick: String?
    var channel_id: String
    var guild_id: String?
    var content: String
    var edited_timestamps: Bool?
    var id: String
    var embeds: [Embed]?
    var mention_everyone: Bool?
    var mentions: [User?]
    var nonce: String?
    var pinned: Bool?
    var timestamp: String
    var tts: Bool
    var type: Int
    var attachments: [AttachedFiles?]
    var referenced_message: Reply?
    weak var lastMessage: Message?
    
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func delete() {
        let headers = Headers(userAgent: discordUserAgent,
                              contentType: nil,
                              token: AccordCoreVars.shared.token,
                              type: .DELETE,
                              discordHeaders: true,
                              referer: "https://discord.com/channels/\(guild_id ?? "")/\(channel_id)",
                              empty: true)
        Request.fetch(url: URL(string: "\(rootURL)/channels/\(channel_id)/messages/\(id)"), headers: headers)
    }
    func edit(now: String) {
        let headers = Headers(userAgent: discordUserAgent,
                              contentType: nil,
                              token: AccordCoreVars.shared.token,
                              bodyObject: ["content":now],
                              type: .PATCH,
                              discordHeaders: true,
                              referer: "https://discord.com/channels/\(guild_id ?? "")/\(channel_id)",
                              empty: true)
        Request.fetch(url: URL(string: "\(rootURL)/channels/\(channel_id)/messages/\(id)"), headers: headers)
    }
    func isSameAuthor() -> Bool { lastMessage?.author?.id == self.author?.id }
}

final class Reply: Codable, Equatable, Identifiable, Hashable {
    static func == (lhs: Reply, rhs: Reply) -> Bool {
        return lhs.id == rhs.id
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
    var type: Int
    var attachments: [AttachedFiles?]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

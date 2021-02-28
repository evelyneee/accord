//
//  Structures.swift
//  Helselia
//
//  Created by evelyn on 2021-02-28.
//

import Foundation

struct Message: Decodable, Hashable {
    struct author {
        var avatar: URL
        var bot: Bool
        var discriminator: String
        var id: String
        var username: String
    }
    var channel_id: String
    var club_id: String
    var content: String
    var edited_timestamps: Bool
    struct embeds {
        struct author {
            var iconURL: URL
            var name: String
            var proxy_icon_url: URL
            var url: URL
        }
        var color: Int
        var content: String
        var title: String
        enum type {
            case rich
            case video
            case image
        }
    }
    var id: String
    var mention_everyone: Bool
    var mentions_roles: [String]
    var mentions: [String]
    var nonce: Int
    var pinned: Bool
    var reactions: [String: String]
    var timestamp: String
    var tts: Bool
    var type: Int
}

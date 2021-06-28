//
//  Structures.swift
//  Accord
//
//  Created by evelyn on 2021-02-28.
//

import Foundation

public class requests {
    enum requestTypes {
        case GET
        case POST
        case PATCH
        case DELETE
        case PUT
    }
}

enum statusIndicators {
    case online
    case dnd
    case idle
}

struct User: Decodable, Identifiable, Hashable {
    var id: String
    var username: String
    var discriminator: String
    var avatar: String?
    var bot: Bool?
    var system: Bool?
    var mfa_enabled: Bool?
    var locale: String?
    var verified: Bool?
    var email: String?
    var flags: Int?
    var premium_type: Int?
    var public_flags: Int?
}

struct GuildMemberChunkResponse: Decodable {
    var d: GuildMemberChunk
}

struct GuildMemberChunk: Decodable {
    var guild_id: String?
    var members: [GuildMember]?
}

struct GuildMember: Decodable {
    var user: User
}

struct GatewayMessage: Decodable {    
    var d: Message?
}


struct GatewayDeletedMessage: Decodable {
    var d: DeletedMessage?
}

struct DeletedMessage: Decodable, Identifiable {
    var id: String
}

struct Message: Decodable, Identifiable, Hashable {
    var author: User
    var channel_id: String
    var guild_id: String?
    var content: String
    var edited_timestamps: Bool?
    var id: String
    var mention_everyone: Bool?
    var mentions: [User]
    var nonce: String?
    var pinned: Bool?
    var timestamp: String
    var tts: Bool
    var type: Int
    var attachments: [AttachedFiles]
    var referenced_message: Reply?
}

struct Reply: Decodable, Identifiable, Hashable {
    var author: User
    var channel_id: String
    var guild_id: String?
    var content: String
    var edited_timestamps: Bool?
    var id: String
    var mention_everyone: Bool?
    var mentions: [User]
    var nonce: Int?
    var pinned: Bool?
    var timestamp: String
    var tts: Bool
    var type: Int
    var attachments: [AttachedFiles]
}

struct AttachedFiles: Decodable, Identifiable, Hashable {
    var id: String
    var filename: String
    var content_type: String?
    var size: Int
    var url: String
    var proxy_url: String
    var height: Int?
    var width: Int?
}

struct Profile {
    var id: String
    var username: String
    var avatar: Data?
    var discriminator: String
}

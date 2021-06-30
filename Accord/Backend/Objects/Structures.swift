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

class User: Decodable, Identifiable {
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

class GuildMemberChunkResponse: Decodable {
    var d: GuildMemberChunk?
}

class GuildMemberChunk: Decodable {
    var guild_id: String?
    var members: [GuildMember?]
}

class GuildMember: Decodable {
    var user: User?
    var nick: String?
}

class GatewayMessage: Decodable {
    var d: Message?
}


class GatewayDeletedMessage: Decodable {
    var d: DeletedMessage?
}

class DeletedMessage: Decodable {
    var id: String
}

class Message: Decodable {
    var author: User?
    var channel_id: String
    var guild_id: String?
    var content: String
    var edited_timestamps: Bool?
    var id: String
    var mention_everyone: Bool?
    var mentions: [User?]
    var nonce: String?
    var pinned: Bool?
    var timestamp: String
    var tts: Bool
    var type: Int
    var attachments: [AttachedFiles?]
    var referenced_message: Reply?
    deinit {
        print(content, "deallocated")
    }
}

class Reply: Decodable {
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
}

class AttachedFiles: Decodable, Identifiable {
    var id: String
    var filename: String
    var content_type: String?
    var size: Int
    var url: String
    var proxy_url: String
    var height: Int?
    var width: Int?
}

/*
class Profile {
    var id: String
    var username: String
    var avatar: Data?
    var discriminator: String
}
*/

//
//  Structures.swift
//  Accord
//
//  Created by evelyn on 2021-02-28.
//

import Foundation
import SwiftUI

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

enum Nitro {
    case none
    case classic
    case nitro
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
    var t: String
    var d: GuildMemberChunk?
}

class GuildMemberChunk: Decodable {
    var guild_id: String?
    var members: [GuildMember?]
}

class TypingEvent: Decodable {
    var channel_id: String
    var guild_id: String?
    var member: GuildMember?
}

class GuildMember: Decodable {
    var user: User
    var nick: String?
    var roles: [String]?
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

class Message: Decodable, Equatable, Identifiable, Hashable {
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
    var mention_everyone: Bool?
    var mentions: [User?]
    var nonce: String?
    var pinned: Bool?
    var timestamp: String
    var tts: Bool
    var type: Int
    var attachments: [AttachedFiles?]
    var referenced_message: Reply?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    func delete() {
        if user_id == id {
            NetworkHandling.shared?.emptyRequest(url: "\(rootURL)/channels/\(channel_id)/\(id)", token: AccordCoreVars.shared.token, json: false, type: .DELETE, bodyObject: [:])
        } else {
            print("[Accord] Deleting other's messages is not yet supported")
        }
    }
}

class Reply: Decodable, Equatable, Identifiable, Hashable {
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

class AttachedFiles: Decodable, Identifiable, Equatable, Hashable {
    static func == (lhs: AttachedFiles, rhs: AttachedFiles) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var filename: String
    var content_type: String?
    var size: Int
    var url: String
    var proxy_url: String
    var height: Int?
    var width: Int?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class DiscordEmote: Decodable, Identifiable, Hashable, Equatable {
    static func == (lhs: DiscordEmote, rhs: DiscordEmote) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var name: String
    var user: User?
    var managed: Bool?
    var animated: Bool?
    var available: Bool?
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class Guild: Decodable {
    var id: String
    var name: String
}

/*
class Profile {
    var id: String
    var username: String
    var avatar: Data?
    var discriminator: String
}
*/

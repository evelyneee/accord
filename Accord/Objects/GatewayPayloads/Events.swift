//
//  Events.swift
//  Events
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation

final class GuildMemberChunkResponse: Decodable {
    var t: String
    var d: GuildMemberChunk?
}

final class GuildMemberChunk: Decodable {
    var guild_id: String?
    var members: [GuildMember?]
    var presences: [Presence]?
}

final class Presence: Codable {
    var user: PresenceUpdate.User?
    // var guild_id: String
    var status: UserStatus?
    var activities: [ActivityCodable]
    //    client_status
}

final class PresenceUpdate: Decodable {
    var user: PresenceUpdate.User
    var guildID: String?
    var status: String
    @IgnoreFailure
    var activities: [ActivityCodable]
    
    enum CodingKeys: String, CodingKey {
        case user, status, activities
        case guildID = "guild_id"
    }
    
    final class User: Codable {
        var id: String
    }
}

enum UserStatus: String, Codable {
    case online
    case dnd
    case idle
    case offline
}

final class TypingEvent: Decodable {
    var d: TypingEventCore
    final class TypingEventCore: Decodable {
        var channel_id: String
        var guild_id: String?
        var member: GuildMember?
        var user_id: String
    }
}

final class GuildMember: Codable {
    internal init(avatar: String? = nil, user: User, nick: String? = nil, roles: [String]? = nil, presence: Presence? = nil) {
        self.avatar = avatar
        self.user = user
        self.nick = nick
        self.roles = roles
        self.presence = presence
    }
    
    var avatar: String?
    var user: User
    var nick: String?
    var roles: [String]?
    var presence: Presence?
}

final class GatewayMessage: Decodable {
    var d: Message
}

final class GatewayDeletedMessage: Decodable {
    var d: DeletedMessage?
}

final class DeletedMessage: Decodable {
    var id: String
}

final class GatewayEventContent<T: Decodable>: Decodable {
    var d: T
}

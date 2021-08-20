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
}

final class TypingEvent: Decodable {
    var channel_id: String
    var guild_id: String?
    var member: GuildMember?
}

final class GuildMember: Decodable {
    var user: User
    var nick: String?
    var roles: [String]?
}

final class GatewayMessage: Decodable {
    var d: Message?
}


final class GatewayDeletedMessage: Decodable {
    var d: DeletedMessage?
}

final class DeletedMessage: Decodable {
    var id: String
}

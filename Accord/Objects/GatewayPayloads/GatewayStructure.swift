//
//  GatewayStructure.swift
//  GatewayStructure
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

struct GatewayStructure: Decodable {
    var t: String?
    var d: GatewayD
    var s: Int
    var op: Int
}

struct GatewayD: Decodable {
    var v: Int?
    var user_settings: DiscordSettings
    var user_guild_settings: UserGuildSettings
    var user: User
    var session_id: String
    var read_state: ReadState?
    @IgnoreFailure
    var guilds: [Guild]
    var friend_suggestion_count: Int?
    var country_code: String
    @IgnoreFailure
    var merged_members: [[Guild.MergedMember]]
    @IgnoreFailure
    var private_channels: [Channel]
    @IgnoreFailure
    var users: [User]
    @IgnoreFailure
    var relationships: [Relationship]
}

final class Relationship: Codable, Identifiable {
    var userID: String
    var nickname: String?
    var type: RelationshipType
    var id: String
    
    enum RelationshipType: Int, Codable {
        case none = 0
        case friend = 1
        case blocked = 2
        case incomingFriendRequest = 3
        case outgoingFriendRequest = 4
    }
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nickname, type, id
    }
}

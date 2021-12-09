//
//  GatewayStructure.swift
//  GatewayStructure
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

class GatewayStructure: Decodable {
    var t: String?
    var d: GatewayD
    var s: Int
    var op: Int
}

class GatewayD: Decodable {
    var v: Int?
    // var users: [User]?
    var user_settings: Settings?
    // var user_guild_settings: GuildSettings?
    var user: User
    // var tutorial: Bool?
    var session_id: String
    // var relationships: [Relationship]
    var read_state: ReadState?
    // var private_channels: [Channel]?
    // var merged_members: [[User]]
    @IgnoreFailure
    var guilds: [Guild]
    // var guild_join_requests: [GuildJoinRequest]?
    // var guild_experiments: [GuildExperiment]?
    // var geo_ordered_rtc_regions: [RTCRegion]?
    var friend_suggestion_count: Int?
    // var experiments: [[Int]]
    var country_code: String
    // var consents
    // var connected_accounts: [ConnectedAccount]?
    // var analytics_token: String
    // var _trace
}

final class Relationship: Codable {
    var user_id: String
    var nick: String?
    var type: Int?
    var id: String
}

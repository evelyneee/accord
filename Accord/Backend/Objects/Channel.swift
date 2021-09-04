//
//  Channel.swift
//  Channel
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation

final class Channel: Decodable, Identifiable, Hashable {
    static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.id == rhs.id
    }

    var id: String
    var type: ChannelType
    var guild_id: String?
    var position: Int?
    // TODO: Overwrite objects
    // var permission_overwrites: ?
    var name: String?
    var topic: String?
    var nsfw: Bool?
    var last_message_id: String?
    // var bitrate: Int?
    // var user_limit: Int?
    // var rate_limit_per_user: Int?
    var recipients: [User]?
    var recipient_ids: [String]?
    var icon: String?
    var owner_id: String?
    // var application_id: String?
    var parent_id: String?
    // var last_pin_timestamp: String?
    // TODO: ISO8601 timestamp
    //  var rtc_region: ?
    // var video_quality_mode: Int?
    var message_count: Int?
    var member_count: Int?
    // TODO: Thread metadata object
    // var thread_metadata?
    // TODO: Thread member object
    // var member: User?
    var default_auto_archive_duration: Int?
    // var permissions: String?

    var read_state: ReadStateEntry?
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ChannelType: Int, Decodable {
    case normal = 0
    case dm = 1
    case voice = 2
    case group_dm = 3
    case section = 4
    case guild_news = 5
    case guild_store = 6
    case guild_news_thread = 10
    case guild_public_thread = 11
    case guild_private_thread = 12
    case stage = 13
}

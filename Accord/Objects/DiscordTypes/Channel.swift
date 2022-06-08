//
//  Channel.swift
//  Channel
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation

struct Channel: Decodable, Equatable, Identifiable, Hashable {
    static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: String
    let type: ChannelType
    var guild_id: String?
    var guild_icon: String?
    let position: Int?
    // TODO: Overwrite objects
    var permission_overwrites: [PermissionOverwrites]?
    
    struct PermissionOverwrites: Decodable {
        var allow: Permissions
        var deny: Permissions
        var id: String
        var type: Int
    }
    
    func hasPermission(_ perms: Permissions) -> Bool {
        var allowed = true
        for overwrite in self.permission_overwrites ?? [] {
            if (overwrite.id == user_id ||
                ServerListView.mergedMembers[guild_id ?? "@me"]?.roles.contains(overwrite.id) ?? false) &&
                overwrite.allow.contains(perms) {
                    return true
            }
            if (overwrite.id == user_id ||
                // for the role permissions
               ServerListView.mergedMembers[guild_id ?? "@me"]?.roles.contains(overwrite.id) ?? false ||
                // for the everyone permissions
                overwrite.id == guild_id) &&
                overwrite.deny.contains(perms) {
                    allowed = false
            }
        }
        return allowed
    }

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
    let parent_id: String?
    //  var rtc_region: ?
    // var video_quality_mode: Int?
    // TODO: Thread metadata object
    // var thread_metadata?
    // TODO: Thread member object
    // var member: User?
    var permissions: Int64?
    var read_state: ReadStateEntry?
    var guild_name: String?
    var threads: [Channel]?
    var shown: Bool?

    var computedName: String {
        name ?? recipients?.map(\.username).joined(separator: ", ") ?? "Unknown Channel"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class PartialChannel: Codable {
    var id: String
    var name: String
    var type: ChannelType
}

enum ChannelType: Int, Codable {
    case normal = 0
    case dm = 1
    case voice = 2
    case group_dm = 3
    case section = 4
    case guild_news = 5
    case guild_store = 6
    case unknown1 = 7
    case unknown2 = 8
    case unknown3 = 9
    case guild_news_thread = 10
    case guild_public_thread = 11
    case guild_private_thread = 12
    case stage = 13
    case unknown4 = 14
    case unknown5 = 15
}

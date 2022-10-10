//
//  Channel.swift
//  Channel
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation
import SwiftUI

struct Channel: Decodable, Equatable, Identifiable, Hashable {
    static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.id == rhs.id
    }

    let id: String
    let type: ChannelType
    var guild_id: String?
    var guild_icon: String?
    let position: Int?
    // TODO: Overwrite objects
    var permission_overwrites: [PermissionOverwrites]?
    var name: String?
    var topic: String?
    var nsfw: Bool?
    var last_message_id: String?
    var lastMessageDate: Int64 {
        if let last_message_id, let num = Int(last_message_id) {
            return Int64(((num / 4194304) + 1420070400000))
        }
        return 0
    }
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
    var overridePermissions: Bool?
    var read_state: ReadStateEntry?
    var guild_name: String?
    var threads: [Channel]?
    var shown: Bool?
    var message_count: Int?

    @MainActor var computedName: String {
        name ?? recipients?.map(\.computedUsername).joined(separator: ", ") ?? "Unknown Channel"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    struct PermissionOverwrites: Decodable {
        var allow: Permissions
        var deny: Permissions
        var id: String
        var type: Int
    }

    func hasPermission(_ perms: Permissions) -> Bool {
        var allowed = true
        for overwrite in permission_overwrites ?? [] {
            if overwrite.id == user_id ||
                Storage.mergedMembers[guild_id ?? "@me"]?.roles.contains(overwrite.id) ?? false,
                overwrite.allow.contains(perms)
            {
                return true
            }
            if overwrite.id == user_id ||
                // for the role permissions
                Storage.mergedMembers[guild_id ?? "@me"]?.roles.contains(overwrite.id) ?? false ||
                // for the everyone permissions
                overwrite.id == guild_id,
                overwrite.deny.contains(perms)
            {
                allowed = false
            }
        }
        return allowed
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
    case directory = 14
    case forum = 15
}

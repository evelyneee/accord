//
//  Settings.swift
//  Settings
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

class DiscordSettings: Decodable {
    var theme: SyncedTheme
    var status: String
    var render_reactions: Bool?
    var render_embeds: Bool?
    var message_display_compact: Bool?
    var inline_embed_media: Bool?
    var inline_attachment_media: Bool?
    var guild_positions: [String]
    @IgnoreFailure
    var guild_folders: [GuildFolder]
    var gif_auto_play: Bool?
    var custom_status: Status?
    // var convert_emoticons: Bool?
    // var contact_sync_enabled: Bool?
    var animate_stickers: Int?
    var animate_emoji: Bool?
    // var allow_accessibility_detection: Bool?
    var afk_timeout: Int?
}

final class GuildFolder: Decodable, Hashable {
    internal init(name: String? = nil, color: Int? = nil, guild_ids: [String]) {
        self.name = name
        self.color = color
        self.guild_ids = guild_ids
    }

    static func == (lhs: GuildFolder, rhs: GuildFolder) -> Bool {
        lhs.guild_ids == rhs.guild_ids
    }

    var id: String { UUID().uuidString }
    var name: String?
    var color: Int?
    var guild_ids: [String]
    @DefaultEmptyArray
    var guilds: [Guild]

    var unreadMessages: Bool {
        guilds
            .map { Accord.unreadMessages(guild: $0) }
            .contains(true)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(guild_ids)
    }
}

enum SyncedTheme: String, Codable {
    case dark
    case light
}

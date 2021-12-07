//
//  Settings.swift
//  Settings
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

class Settings: Codable {
    var view_nsfw_guilds: Bool?
    var timezone_offset: Int?
    var theme: SyncedTheme
    var stream_notifications_enabled: Bool?
    var status: String
    var show_current_game: Bool?
    var render_reactions: Bool?
    var render_embeds: Bool?
    var native_phone_integration_enabled: Bool?
    var message_display_compact: Bool?
    // var locale: String?
    var inline_embed_media: Bool?
    var inline_attachment_media: Bool?
    var guild_positions: [String]
    var guild_folders: [GuildFolder]
    var gif_auto_play: Bool?
    // var friend_source_flags:
    // var friend_discovery_flags: Int?
    // var explicit_content_filter: Int?
    // var enable_tts_command: Bool?
    // var disable_games_tab: Bool?
    // var developer_mode: Bool?
    // var detect_platform_accounts: Bool?
    // var default_guilds_restricted: Bool?
    var custom_status: Status?
    // var convert_emoticons: Bool?
    // var contact_sync_enabled: Bool?
    var animate_stickers: Int?
    var animate_emoji: Bool?
    // var allow_accessibility_detection: Bool?
    var afk_timeout: Int?
}

final class GuildFolder: Codable, Hashable {
    static func == (lhs: GuildFolder, rhs: GuildFolder) -> Bool {
        return lhs.guild_ids == rhs.guild_ids
    }
    var id: Int?
    var name: String?
    var color: Int?
    var guild_ids: [String]
    var guilds: [Guild]?
    func hash(into hasher: inout Hasher) {
        return hasher.combine(guild_ids)
    }
}

enum SyncedTheme: String, Codable {
    case dark = "dark"
    case light = "light"
}

//
//  Settings.swift
//  Settings
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

class Settings: Decodable {
    var view_nsfw_guilds: Bool?
    var timezone_offset: Int?
    var theme: String
    var stream_notifications_enabled: Bool?
    var status: String
    var show_current_game: Bool?
    var render_reactions: Bool?
    var render_embeds: Bool?
    var native_phone_integration_enabled: Bool?
    var message_display_compact: Bool?
    var locale: String?
    var inline_embed_media: Bool?
    var inline_attachment_media: Bool?
    var guild_positions: [String]
    // var guild_folders:
    var gif_auto_play: Bool?
    // var friend_source_flags:
    var friend_discovery_flags: Int?
    var explicit_content_filter: Int?
    var enable_tts_command: Bool?
    var disable_games_tab: Bool?
    var developer_mode: Bool?
    var detect_platform_accounts: Bool?
    var default_guilds_restricted: Bool?
    var custom_status: Status?
    var convert_emoticons: Bool?
    var contact_sync_enabled: Bool?
    var animate_stickers: Int?
    var animate_emoji: Bool?
    var allow_accessibility_detection: Bool?
    var afk_timeout: Int?
}

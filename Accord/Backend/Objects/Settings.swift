//
//  Settings.swift
//  Settings
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

class Settings: Decodable {
    var theme: SyncedTheme
    var status: String
    var render_reactions: Bool?
    var render_embeds: Bool?
    var message_display_compact: Bool?
    var inline_embed_media: Bool?
    var inline_attachment_media: Bool?
    var guild_positions: [String]
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
    static func == (lhs: GuildFolder, rhs: GuildFolder) -> Bool {
        return lhs.guild_ids == rhs.guild_ids
    }
    var id: Int?
    var name: String?
    var color: Int?
    var guild_ids: [String]
    @DefaultEmptyArray var guilds: [Guild]
    func hash(into hasher: inout Hasher) {
        return hasher.combine(guild_ids)
    }
}

enum SyncedTheme: String, Codable {
    case dark = "dark"
    case light = "light"
}

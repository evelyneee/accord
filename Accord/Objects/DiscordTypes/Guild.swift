//
//  Guild.swift
//  Guild
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation

struct Guild: Decodable, Equatable, Hashable, Identifiable {
    static func == (lhs: Guild, rhs: Guild) -> Bool {
        lhs.id == rhs.id
    }

    let id: String
    let name: String?
    var icon: String?
    var icon_hash: String?
    // var splash: String?
    // var discovery_splash: String?
    var owner: Bool?
    var owner_id: String
    // var region: String?
    // var afk_channel_id: String?
    // var afk_timeout: Int
    // var widget_enabled: Bool?
    // var widget_channel_id: String?
    // var verification_level: Int
    // var default_message_notification: Int?
    // var explicit_content_filter: Int
    // TODO: Role object
    var roles: [Role]?
    var emojis: [DiscordEmote]
    // TODO: Guild features
    // var features:
    var mfa_level: Int
    // var application_id: String?
    // var system_channel_id: String?
    // var system_channel_flags: Int?
    // var rules_channel_id: String?
    // TODO: ISO8061 timestamp
    // var joined_at: ISO8061
    var large: Bool?
    var unavailable: Bool?
    var member_count: Int?
    // TODO: Voice state object
    // var voice_states: [VoiceState]
    // var members: [GuildMember]?
    var channels: [Channel]?
    // TODO: Thread object
    var threads: [Channel]?
    // TODO: PresenceUpdate object
    // var presences: [PresenceUpdate]?
    let max_presences: Int?
    let max_members: Int?
    var vanity_url_code: String?
    var description: String?
    var banner: String?
    var premium_tier: Int?
    var premium_subscription_count: Int?
    // var preferred_locale: String?
    // var public_updates_channel_id: String?
    // var max_video_channel_users: Int?
    var approximate_member_count: Int?
    var approximate_presence_count: Int?
    // TODO: Welcome Screen object
    // var welcome_screen: WelcomeScreen
    var nsfw_level: Int
    // TODO: StageInstance objects
    // var stage_instances: [StageInstances]
    // var stickers: [Sticker]?

    var index: Int?
    var mergedMember: MergedMember?
    var guildPermissions: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    struct MergedMember: Decodable {
        var guild_id: String?
        var hoisted_role: String?
        var nick: String?
        var roles: [String]
        var cachedPermissions: Permissions?
    }
}

//
//  UserGuildSettings.swift
//  Accord
//
//  Created by evelyn on 2022-10-02.
//

import Foundation

class UserGuildSettings: ObservableObject, Decodable {
    
    var entries: [UserGuildSettingsEntry]
    
    var mutedChannels: Set<String>
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let entries = try? container.decode([UserGuildSettings.UserGuildSettingsEntry].self, forKey: .entries) {
            self.entries = entries
        } else {
            self.entries = []
        }
        
        self.mutedChannels = Set(self.entries
            .map(\.overrides)
            .joined()
            .filter { $0.muted }
            .map {
                $0.channelID
            })
    }
    
    init() {
        self.entries = []
        self.mutedChannels = []
    }
    
    struct UserGuildSettingsEntry: Codable {
        var guildID: String?
        var overrides: [ChannelOverride]
        
        enum CodingKeys: String, CodingKey {
            case guildID = "guild_id"
            case overrides = "channel_overrides"
        }
        
        struct ChannelOverride: Codable {
            var muted: Bool
            var messageNotifications: Int
            var collapsed: Bool
            var channelID: String
            
            enum CodingKeys: String, CodingKey {
                case muted
                case messageNotifications = "message_notifications"
                case collapsed
                case channelID = "channel_id"
            }
        }
    }
    
    enum CodingKeys: CodingKey {
        case entries
    }
}

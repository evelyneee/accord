//
//  Emote.swift
//  Emote
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation

final class DiscordEmote: Codable, Identifiable, Hashable, Equatable {
    static func == (lhs: DiscordEmote, rhs: DiscordEmote) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var name: String
    var managed: Bool?
    var animated: Bool?
    var available: Bool?
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//
//  Emote.swift
//  Emote
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation

struct DiscordEmote: Codable, Identifiable {
    var id: String
    var name: String
    var animated: Bool?
}

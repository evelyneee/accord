//
//  Reaction.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation

final class Reaction: Codable {
    var count: Int
    var me: Bool
    var emoji: ReactionEmote
    var identifier: String { self.emoji.id ?? emoji.name ?? "some emoji" }
}

final class ReactionEmote: Codable {
    var id: String?
    var name: String?
    var animated: Bool?
}

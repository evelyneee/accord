//
//  Reaction.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation

final class Reaction: Identifiable, Hashable, Codable {
    static func == (lhs: Reaction, rhs: Reaction) -> Bool {
        return lhs.id == rhs.id && lhs.me == rhs.me && lhs.count == rhs.count
    }
    
    var count: Int
    var me: Bool
    var emoji: ReactionEmote
    var id: String { identifier }
    var identifier: String { emoji.id ?? emoji.name ?? "some emoji" }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(me)
        hasher.combine(count)
    }
}

final class ReactionEmote: Codable {
    var id: String?
    var name: String?
    var animated: Bool?
}

//
//  Reaction.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation

final public class Reaction: Identifiable, Hashable, Codable {
    internal init(count: Int, me: Bool, emoji: ReactionEmote) {
        self.count = count
        self.me = me
        self.emoji = emoji
    }
    
    static public func == (lhs: Reaction, rhs: Reaction) -> Bool {
        return lhs.id == rhs.id && lhs.me == rhs.me && lhs.count == rhs.count
    }
    
    var count: Int
    var me: Bool
    var emoji: ReactionEmote
    public var id: String { identifier }
    var identifier: String { emoji.id ?? emoji.name ?? "some emoji" }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(me)
        hasher.combine(count)
        hasher.combine(emoji.id)
        hasher.combine(emoji.name)
    }
}

final class ReactionEmote: Codable {
    internal init(id: String? = nil, name: String? = nil, animated: Bool? = nil) {
        self.id = id
        self.name = name
        self.animated = animated
    }
    
    var id: String?
    var name: String?
    var animated: Bool?
}

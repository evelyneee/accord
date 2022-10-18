//
//  Sticker.swift
//  Sticker
//
//  Created by evelyn on 2021-08-31.
//

import Foundation

final class Sticker: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var pack_id: String?
    var name: String
    var description: String?
    var tags: String
    var type: StickerType
    var format_type: StickerFormat
    var available: Bool?
    var guild_id: String?
    var user: User?
    var sort_value: Int?
    
    static func == (lhs: Sticker, rhs: Sticker) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum StickerType: Int, Codable {
    case standard = 1
    case guild = 2
}

enum StickerFormat: Int, Codable {
    case png = 1
    case apng = 2
    case lottie = 3
}

final class StickerItem: Codable {
    var id: String
    var name: String
    var format_type: StickerFormat
}

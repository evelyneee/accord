//
//  Sticker.swift
//  Sticker
//
//  Created by evelyn on 2021-08-31.
//

import Foundation

final class Sticker: Decodable {
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
}

enum StickerType: Int, Decodable {
    case standard = 1
    case guild = 2
}

enum StickerFormat: Int, Decodable {
    case png = 1
    case apng = 2
    case lottie = 3
}

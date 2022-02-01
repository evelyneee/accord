//
//  Embed.swift
//  Accord
//
//  Created by evelyn on 2021-10-24.
//

import Foundation

final class Embed: Codable, Hashable, Identifiable {
    static func == (lhs: Embed, rhs: Embed) -> Bool {
        lhs.id == rhs.id
    }

    var title: String?
    var type: String?
    var description: String?
    var url: String?
    var timestamp: String?
    var color: Int?
    var image: EmbedImage?
//    var thumbnail?    mation
//    var video?    embe
//    var provider?    eion
    var author: EmbedAuthor?
    var fields: [EmbedField]?
    var id: String { UUID().uuidString }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class EmbedField: Codable {
    var name: String
    var inline: Bool?
    var value: String
}

final class EmbedAuthor: Codable {
    var name: String
    var url: String?
    var icon_url: String?
    var proxy_icon_url: String?
}

class EmbedImage: Codable {
    var url: String
    var proxy_url: String?
    var height: Int?
    var width: Int?
}

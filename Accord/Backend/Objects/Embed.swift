//
//  Embed.swift
//  Accord
//
//  Created by evelyn on 2021-10-24.
//

import Foundation

final class Embed: Codable, Hashable, Identifiable {
    static func == (lhs: Embed, rhs: Embed) -> Bool {
        return lhs.id == rhs.id
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
//    var author?    emb
//    var fields?
    var id: String? = UUID().uuidString
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class EmbedImage: Codable {
    var url: String
    var proxy_url: String?
    var height: Int?
    var width: Int?
}

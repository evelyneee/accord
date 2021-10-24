//
//  Embed.swift
//  Accord
//
//  Created by evelyn on 2021-10-24.
//

import Foundation

final class Embed: Decodable {
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
}

class EmbedImage: Decodable {
    var url: String
    var proxy_url: String?
    var height: Int?
    var width: Int?
}

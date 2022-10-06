//
//  Attachments.swift
//  Attachments
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation
import SwiftUI

final class AttachedFiles: Codable, Identifiable, Equatable, Hashable {
    static func == (lhs: AttachedFiles, rhs: AttachedFiles) -> Bool {
        lhs.id == rhs.id
    }

    var id: String
    var filename: String
    var description: String?
    var contentType: String?
    var size: Int
    var url: String
    var proxyURL: String
    var height: Int?
    var width: Int?

    var isVideo: Bool {
        contentType?.prefix(6) == "video/"
    }

    var isImage: Bool {
        contentType?.prefix(6) == "image/"
    }

    var isFile: Bool {
        !(isImage || isVideo)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case filename
        case description
        case contentType = "content_type"
        case size
        case url
        case proxyURL = "proxy_url"
        case height
        case width
    }
}

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
    var content_type: String?
    var size: Int
    var url: String
    var proxy_url: String
    var height: Int?
    var width: Int?

    var isVideo: Bool {
        content_type?.prefix(6) == "video/"
    }

    var isImage: Bool {
        content_type?.prefix(6) == "image/"
    }

    var isFile: Bool {
        !(isImage || isVideo)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

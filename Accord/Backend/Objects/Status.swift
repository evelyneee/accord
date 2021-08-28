//
//  Status.swift
//  Status
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

class Status: Decodable {
    var text: String?
    var expires_at: Int?
    var emoji_name: String?
    var emoji_id: String?
}

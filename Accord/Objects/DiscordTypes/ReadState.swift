//
//  ReadState.swift
//  ReadState
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

class ReadState: Decodable {
    var version: Int?
    var partial: Bool?
    @IgnoreFailure
    var entries: [ReadStateEntry]
}

class ReadStateEntry: Decodable, Identifiable {
    var mention_count: Int
    var last_pin_timestamp: String
    var last_message_id: String?
    var id: String // Channel ID
}

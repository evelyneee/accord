//
//  ReadState.swift
//  ReadState
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

class ReadState: Codable {
    var version: Int?
    var partial: Bool?
    var entries: [ReadStateEntry]
}

class ReadStateEntry: Codable {
    var mention_count: Int
    var last_pin_timestamp: String
    var last_message_id: StringOrInt?
    var id: String // Channel ID
}

struct StringOrInt: Codable {
    var string: String?
    var int: Int?

    // Where we determine what type the value is
    init(from decoder: Decoder) throws {
        let container =  try decoder.singleValueContainer()

        // Check for a boolean
        do {
            string = nil
            string = try container.decode(String.self)
        } catch {
            int = nil
            // Check for an integer
            int = try container.decode(Int.self)
        }
    }
}

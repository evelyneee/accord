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

class ReadStateEntry: Decodable, Hashable, Identifiable, Equatable {
    var mention_count: Int?
    var last_pin_timestamp: String?
    var last_message_id: String?
    var id: String
    
    static func == (lhs: ReadStateEntry, rhs: ReadStateEntry) -> Bool {
        return lhs.mention_count == rhs.mention_count &&
        lhs.last_message_id == rhs.last_message_id
    } // Channel ID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(mention_count)
        hasher.combine(last_message_id)
    }
}

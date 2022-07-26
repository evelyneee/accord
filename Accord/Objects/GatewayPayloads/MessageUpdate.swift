//
//  MessageUpdate.swift
//  Accord
//
//  Created by evelyn on 2022-07-25.
//

import Foundation

struct MessageUpdate: Codable {
    var id: String
    var channelID: String
    var embeds: [Embed]
    
    enum CodingKeys: String, CodingKey {
        case id, embeds
        case channelID = "channel_id"
    }
}

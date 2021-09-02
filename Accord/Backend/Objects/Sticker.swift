//
//  Sticker.swift
//  Sticker
//
//  Created by evelyn on 2021-08-31.
//

import Foundation

final class Sticker: Decodable {
    var id: String
    var pack_id: String?
    var name: String
    var description: String?
    var tags: String
    
    /// STANDARD - 1
    /// GUILD - 2
    var type: Int
    
    /// PNG - 1
    /// APNG - 2
    /// LOTTIE - 3
    var format_type: Int
    
    var available: Bool?
    var guild_id: String?
    var user: User?
    var sort_value: Int?
}

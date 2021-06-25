//
//  NitrolessStructures.swift
//  Accord
//
//  Created by evelyn on 2021-06-25.
//

import Foundation

struct Repo: Decodable {
    var name: String
    var emotes: [Emote]
}

struct Emote: Decodable {
    var name: String
    var type: String
}

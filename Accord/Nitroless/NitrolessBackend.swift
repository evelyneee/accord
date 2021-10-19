//
//  NitrolessBackend.swift
//  NitrolessBackend
//
//  Created by evelyn on 2021-10-17.
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

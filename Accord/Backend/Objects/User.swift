//
//  User.swift
//  User
//
//  Created by Evelyn on 2021-08-16.
//

import Foundation

final class User: Decodable, Identifiable {
    var id: String
    var username: String
    var discriminator: String
    var avatar: String?
    var bot: Bool?
    var system: Bool?
    var mfa_enabled: Bool?
    var locale: String?
    var verified: Bool?
    var email: String?
    var flags: Int?
    var premium_type: Int?
    var public_flags: Int?
    var bio: String?
    // Not part of decodable
    var nick: String?
    var roleColor: String?
    var pfp: Data?
}

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
    var premium_type: NitroTypes?
    var public_flags: Int?
    var bio: String?
    // Not part of decodable
    var nick: String?
    var roleColor: String?
    var pfp: Data?
    func isMe() -> Bool { user_id == self.id }
    
    // MARK: - Relationships
    func addFriend(_ guild: String, _ channel: String) {
        NetworkHandling.shared.emptyRequest(url: "\(rootURL)/users/@me/relationships/\(id)", referer: "https://discord.com/channels/\(guild)/\(channel)", token: AccordCoreVars.shared.token, json: false, type: .PUT, bodyObject: [:])
    }
    func removeFriend(_ guild: String, _ channel: String) {
        NetworkHandling.shared.emptyRequest(url: "\(rootURL)/users/@me/relationships/\(id)", referer: "https://discord.com/channels/\(guild)/\(channel)", token: AccordCoreVars.shared.token, json: false, type: .DELETE, bodyObject: [:])
    }
    func block(_ guild: String, _ channel: String) {
        NetworkHandling.shared.emptyRequest(url: "\(rootURL)/users/@me/relationships/\(id)", referer: "https://discord.com/channels/\(guild)/\(channel)", token: AccordCoreVars.shared.token, json: false, type: .PUT, bodyObject: ["type":2])
    }
}

enum NitroTypes: Int, Decodable {
    case none = 0
    case classic = 1
    case nitro = 2
}

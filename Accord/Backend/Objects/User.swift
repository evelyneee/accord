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
        let headers = Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .PUT,
            discordHeaders: true,
            referer: "https://discorc.com/channels/\(guild)/\(channel)"
        )
        Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/users/@me/relationships/\(id)"), headers: headers) { _ in }
    }
    func removeFriend(_ guild: String, _ channel: String) {
        let headers = Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .DELETE,
            discordHeaders: true,
            referer: "https://discorc.com/channels/\(guild)/\(channel)"
        )
        Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/users/@me/relationships/\(id)"), headers: headers) { _ in }
    }
    func block(_ guild: String, _ channel: String) {
        let headers = Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            bodyObject: ["type":2],
            type: .PUT,
            discordHeaders: true,
            referer: "https://discorc.com/channels/\(guild)/\(channel)"
        )
        Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/users/@me/relationships/\(id)"), headers: headers) { _ in }
    }
}

enum NitroTypes: Int, Decodable {
    case none = 0
    case classic = 1
    case nitro = 2
}

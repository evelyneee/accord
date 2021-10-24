//
//  Message.swift
//  Message
//
//  Created by evelyn on 2021-08-16.
//

import Foundation

final class Message: Decodable, Equatable, Identifiable, Hashable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    var author: User?
    var nick: String?
    var roleColor: String?
    var channel_id: String
    var guild_id: String?
    var content: String
    var edited_timestamps: Bool?
    var id: String
    var embeds: [Embed]?
    var mention_everyone: Bool?
    var mentions: [User?]
    var nonce: String?
    var pinned: Bool?
    var timestamp: String
    var tts: Bool
    var type: Int
    var attachments: [AttachedFiles?]
    var referenced_message: Reply?
    weak var lastMessage: Message?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func delete() {
        let headers = Headers(userAgent: discordUserAgent,
                              contentType: nil,
                              token: AccordCoreVars.shared.token,
                              type: .DELETE,
                              discordHeaders: true,
                              empty: true)
        Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/channels/\(channel_id)/messages/\(id)"), headers: headers) { _ in }
    }
    func edit(now: String) {
        let headers = Headers(userAgent: discordUserAgent,
                              contentType: nil,
                              token: AccordCoreVars.shared.token,
                              bodyObject: ["content":now],
                              type: .PATCH,
                              discordHeaders: true,
                              empty: true)
        Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/channels/\(channel_id)/messages/\(id)"), headers: headers) { _ in }
    }
    func isSameAuthor() -> Bool { lastMessage?.author?.id == self.author?.id }
}

final class Reply: Decodable, Equatable, Identifiable, Hashable {
    static func == (lhs: Reply, rhs: Reply) -> Bool {
        return lhs.id == rhs.id
    }
    
    var author: User?
    var channel_id: String
    var guild_id: String?
    var content: String
    var edited_timestamps: Bool?
    var id: String
    var mention_everyone: Bool?
    var mentions: [User?]
    var nonce: Int?
    var pinned: Bool?
    var timestamp: String
    var tts: Bool
    var type: Int
    var attachments: [AttachedFiles?]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

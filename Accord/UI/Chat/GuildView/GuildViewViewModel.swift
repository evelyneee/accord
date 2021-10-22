//
//  GuildViewViewModel.swift
//  Accord
//
//  Created by evelyn on 2021-10-22.
//

import Foundation
import AppKit

final class GuildViewViewModel: ObservableObject {
    
    @Published var messages = [Message]()
    
    init(channelID: String, guildID: String) {
        // messages are now read
        MentionSender.shared.removeMentions(server: guildID)
        // fetch messages
        self.getMessages(channelID: channelID, guildID: guildID)
        // Fix up UI and
        self.assignPositions()
        self.ack(channelID: channelID, guildID: guildID)
    }
    
    func assignPositions() {
        for (index, message) in messages.enumerated() {
            if message != messages.last {
                message.lastMessage = messages[index + 1]
            }
        }
        self.messages = messages
    }
    
    func ack(channelID: String, guildID: String) {
        Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(messages.first?.id ?? "")/ack")!, headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .POST,
            discordHeaders: true,
            referer: "\(rootURL)/channels/\(guildID)/\(channelID)"
        )) { nothing in }
    }
    
    func getMessages(channelID: String, guildID: String) {
        Networking<[Message]>().combineFetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .GET,
            discordHeaders: true,
            referer: "\(rootURL)/channels/\(guildID)/\(channelID)"
        ))
        .replaceError(with: [])
        .receive(on: DispatchQueue.main)
        .assign(to: &$messages)
    }
}

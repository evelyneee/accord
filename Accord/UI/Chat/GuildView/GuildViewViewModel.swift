//
//  GuildViewViewModel.swift
//  Accord
//
//  Created by evelyn on 2021-10-22.
//

import Foundation
import AppKit
import Combine

final class GuildViewViewModel: ObservableObject {
    
    @Published var messages = [Message]()
    
    var requestCancellable: AnyCancellable?

    
    init(channelID: String, guildID: String) {
        // messages are now read
        MentionSender.shared.removeMentions(server: guildID)
        // fetch messages
        self.getMessages(channelID: channelID, guildID: guildID)
        // ACK
        self.ack(channelID: channelID, guildID: guildID)
    }
    
    func ack(channelID: String, guildID: String) {
        Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(messages.first?.id ?? "")/ack")!, headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        )) { _ in }
    }
    
    func processRoleColors(roles: [String:String]) {
        // roleColors[(roles[message.author?.id ?? ""] ?? [])[0]]
        let allIDs = messages.map { $0.author?.id ?? "" }
        for id in allIDs {
            let color = NSColor.color(from: roleColors[roles[id] ?? ""]?.0 ?? 0)
            roleColors[roles[id] ?? ""]?.2 = color
        }
    }
    
    func getMessages(channelID: String, guildID: String) {
        requestCancellable = Networking<[Message]>().combineFetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
        .replaceError(with: [])
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
        .sink(receiveValue: { msg in
            self.messages = msg.enumerated().compactMap { (index, element) -> Message in
                if element != msg.last {
                    element.lastMessage = msg[index + 1]
                }
                return element
            }
        })
    }
}

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
    @Published var nicks: [String:String] = [:]
    @Published var roles: [String:String] = [:]
    @Published var refresh: Bool = false
    
    var requestCancellable: AnyCancellable?
    
    var guildID: String
    var channelID: String
    
    init(channelID: String, guildID: String) {
        self.channelID = channelID
        self.guildID = guildID
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
        let allIDs = messages.map { $0.author?.id ?? "" }
        for id in allIDs {
            let color = NSColor.color(from: roleColors[roles[id] ?? ""]?.0 ?? 0)
            roleColors[roles[id] ?? ""]?.2 = color
        }
        DispatchQueue.main.async {
            self.refresh.toggle()
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
    
    func getCachedMemberChunk() {
        let allUserIDs = Array(NSOrderedSet(array: messages.map { $0.author?.id ?? "" })) as! Array<String>
        for user in allUserIDs {
            if let person = wss.cachedMemberRequest["\(guildID)$\(user)"] {
                let nickname = person.nick ?? person.user.username
                DispatchQueue.main.async { [weak self] in
                    self!.nicks[(person.user.id)] = nickname
                }
                var rolesTemp: [String] = Array.init(repeating: "", count: 50)
                
                for role in (person.roles ?? []) {
                    rolesTemp[roleColors[role]?.1 ?? 0] = role
                }
                
                rolesTemp = rolesTemp.compactMap { role -> String? in
                    if role == "" {
                        return nil
                    } else {
                        return role
                    }
                }.reversed()
                DispatchQueue.main.async { [weak self] in
                    self?.roles[(person.user.id)] = (rolesTemp.indices.contains(0) ? rolesTemp[0] : "")
                }
            }
        }
    }
    
    func performSecondStageLoad() {
        if guildID != "@me" {
            var allUserIDs = Array(NSOrderedSet(array: messages.map { $0.author?.id ?? "" })) as! Array<String>
            getCachedMemberChunk()
            for (index, item) in allUserIDs.enumerated() {
                if Array(wss.cachedMemberRequest.keys).contains("\(guildID)$\(item)") && Array<Int>(allUserIDs.indices).contains(index) {
                    allUserIDs.remove(at: index)
                }
            }
            if !(allUserIDs.isEmpty) {
                wss.getMembers(ids: allUserIDs, guild: guildID)
            }
        }
    }
}

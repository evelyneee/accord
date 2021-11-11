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
    
    var requestCancellable: AnyCancellable?
    
    var guildID: String
    var channelID: String
    
    init(channelID: String, guildID: String) {
        self.channelID = channelID
        self.guildID = guildID
        // messages are now read
        switch self.guildID == "@me" {
        case true:
            wss.subscribeToDM(channelID)
        case false:
            wss.subscribe(guildID, channelID)
        }
        DispatchQueue(label: "Message Fetch Queue").async {
            MentionSender.shared.removeMentions(server: guildID)
            // fetch messages
            self.getMessages(channelID: channelID, guildID: guildID)
        }
        self.ack(channelID: channelID, guildID: guildID)
    }
    
    func ack(channelID: String, guildID: String) {
        Request().fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(messages.first?.id ?? "")/ack")!, headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
    }
    
    func getMessages(channelID: String, guildID: String) {
        if Thread.isMainThread {
            fatalError("Time consuming operations should not be called from main thread")
        }
        requestCancellable = Request().combineFetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
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
            DispatchQueue(label: "Channel loading").async { self.performSecondStageLoad(); self.loadAvatars() }
            self.fakeNicksObject()
        })
    }
    
    func loadUser(for id: String?) {
        guard let id = id else { return }
        wss.getMembers(ids: [id], guild: guildID)
    }
    
    func fakeNicksObject() {
        guard self.guildID == "@me" else { return }
        self.nicks = messages.compactMap { [ $0.author?.id ?? "" : $0.author?.username ?? "" ] }
        .flatMap { $0 }
        .reduce([String:String]()) { (dict, tuple) in
            var nextDict = dict
            nextDict.updateValue(tuple.1, forKey: tuple.0)
            return nextDict
        }
    }
    
    func getCachedMemberChunk() {
        let allUserIDs = Array(NSOrderedSet(array: messages.map { $0.author?.id ?? "" })) as! Array<String>
        for person in allUserIDs.compactMap({ wss.cachedMemberRequest["\(guildID)$\($0)"] }) {
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
    func loadAvatars() {
        for user in messages.compactMap({ $0.author }) {
            user.loadPfp()
        }
        for message in messages {
            message.referenced_message?.author?.loadPfp()
        }
    }
}

extension Array where Array.Element: Hashable {
    func unique() -> some Collection {
        return Array(Set(self))
    }
}

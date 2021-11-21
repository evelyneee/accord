//
//  ChannelViewViewModel.swift
//  Accord
//
//  Created by evelyn on 2021-10-22.
//

import Foundation
import AppKit
import Combine


@propertyWrapper class DispatchToMain<T> {
    var wrappedValue: () -> T
    init(wrappedValue: @escaping () -> T) {
        self.wrappedValue = {
            DispatchQueue.main.sync { return wrappedValue() }
        }
    }
}

final class ChannelViewViewModel: ObservableObject {
    
    @Published var messages = [Message]()
    @Published var nicks: [String:String] = [:]
    @Published var roles: [String:String] = [:]
    @Published var colors: [String:NSColor] = [:]
    
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
    }
    
    func ack(channelID: String, guildID: String) {
        guard let first = messages.first?.id else { return }
        Request.fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(first)/ack")!, headers: Headers(
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
        requestCancellable = Request.combineFetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
        .replaceError(with: [])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { msg in
            let messages: [Message] = msg.enumerated().compactMap { (index, element) -> Message in
                guard element != msg.last else { return element }
                element.lastMessage = msg[index + 1]
                return element
            }
            self.messages = messages
            DispatchQueue(label: "Channel loading").async { self.performSecondStageLoad(); self.loadAvatars() }
            self.fakeNicksObject()
            self.ack(channelID: channelID, guildID: guildID)
        })
    }
    
    func loadUser(for id: String?) {
        guard let id = id else { return }
        wss.getMembers(ids: [id], guild: guildID)
    }
    
    func fakeNicksObject() {
        guard self.guildID == "@me" else { return }
        let _nicks: [String:String] = messages.compactMap { [ $0.author?.id ?? "" : $0.author?.username ?? "" ] }
        .flatMap { $0 }
        .reduce([String:String]()) { (dict, tuple) in
            var nextDict = dict
            nextDict.updateValue(tuple.1, forKey: tuple.0)
            return nextDict
        }
        self.nicks = _nicks
    }
    
    func getCachedMemberChunk() {
        let allUserIDs = Array(NSOrderedSet(array: messages.map { $0.author?.id ?? "" })) as! Array<String>
        for person in allUserIDs.compactMap({ wss.cachedMemberRequest["\(guildID)$\($0)"] }) {
            wss.cachedMemberRequest["\(guildID)$\(person.user.id)"] = person
            let nickname = person.nick ?? person.user.username
            DispatchQueue.main.async {
                self.nicks[(person.user.id)] = nickname
            }
            
            if let roles = person.roles {
                var rolesTemp: [String?] = Array.init(repeating: nil, count: 100)
                for role in roles {
                    if let roleColor = roleColors[role]?.1 {
                        rolesTemp[roleColor] = role
                    }
                }
                let temp: [String] = rolesTemp.compactMap { $0 }
                if !(temp.isEmpty) {
                    DispatchQueue.main.async {
                        self.roles[(person.user.id)] = temp[0]
                    }
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

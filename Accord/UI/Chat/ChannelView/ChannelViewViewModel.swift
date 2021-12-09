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
    @Published var pronouns: [String:String] = [:]
    
    private var requestCancellable: AnyCancellable?
    private var pronounCancellable: AnyCancellable?

    var guildID: String
    var channelID: String
    
    init(channelID: String, guildID: String) {
        self.channelID = channelID
        self.guildID = guildID
        DispatchQueue(label: "Message Fetch Queue").async {
            switch self.guildID == "@me" {
            case true:
                wss.subscribeToDM(channelID)
            case false:
                wss.subscribe(guildID, channelID)
            }
            MentionSender.shared.removeMentions(server: guildID)
            // fetch messages
            self.getMessages(channelID: channelID, guildID: guildID)
        }
    }
    
    func ack(channelID: String, guildID: String) {
        guard let first = messages.first?.id else { return }
        Request.fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(first)/ack"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
    }
    
    func getMessages(channelID: String, guildID: String) {
        requestCancellable = RequestPublisher.fetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case .failure(let error):
                releaseModePrint(error)
                MentionSender.shared.deselect()
            }
        }, receiveValue: { msg in
            let messages: [Message] = msg.enumerated().compactMap { (index, element) -> Message in
                guard element != msg.last else { return element }
                element.lastMessage = msg[index + 1]
                return element
            }
            DispatchQueue.main.async {
                self.messages = messages
                DispatchQueue(label: "Channel loading").async {
                    self.performSecondStageLoad()
                    self.loadPronouns()
                    self.fakeNicksObject()
                    self.ack(channelID: channelID, guildID: guildID)
                }
            }
        })
    }
    
    func loadUser(for id: String?) {
        guard let id = id else { return }
        guard let person = wss.cachedMemberRequest["\(guildID)$\(id)"] else {
            wss.getMembers(ids: [id], guild: guildID)
            return
        }
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
    
    func fakeNicksObject() {
        guard self.guildID == "@me" else { return }
        let _nicks: [String:String] = messages.compactMap { [ $0.author?.id ?? "" : $0.author?.username ?? "" ] }
        .flatMap { $0 }
        .reduce([String:String]()) { (dict, tuple) in
            var nextDict = dict
            nextDict.updateValue(tuple.1, forKey: tuple.0)
            return nextDict
        }
        DispatchQueue.main.async {
            self.nicks = _nicks
        }
    }
    
    func loadPronouns() {
        guard AccordCoreVars.shared.pronounDB else { return }
        pronounCancellable = RequestPublisher.fetch([String:String].self, url: URL(string: "https://pronoundb.org/api/v1/lookup-bulk"), headers: Headers(
            bodyObject: ["platform":"discord", "ids":messages.compactMap({ $0.author?.id}).joined(separator: ",")],
            type: .GET
        ))
        .sink(receiveCompletion: { _ in
        }, receiveValue: { value in
            print(value)
            var value = value
            for key in value.keys {
                pronounDBFormed(pronoun: &value[key])
            }
            DispatchQueue.main.async {
                self.pronouns = value
            }
        })

    }
    
    func getCachedMemberChunk() {
        let allUserIDs = messages.map { $0.author?.id ?? "" }
                            .removingDuplicates()
        for person in allUserIDs.compactMap({ wss.cachedMemberRequest["\(guildID)$\($0)"] }) {
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
            print("hi")
            if !(allUserIDs.isEmpty) {
                print(allUserIDs)
                wss.getMembers(ids: allUserIDs, guild: guildID)
            }
        }
    }
}

extension Array where Array.Element: Hashable {
    func unique() -> some Collection {
        return Array(Set(self))
    }
}

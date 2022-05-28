//
//  ChannelViewViewModel.swift
//  Accord
//
//  Created by evelyn on 2021-10-22.
//

import AppKit
import Combine
import Foundation
import SwiftUI

final class ChannelViewViewModel: ObservableObject, Equatable {
    static func == (lhs: ChannelViewViewModel, rhs: ChannelViewViewModel) -> Bool {
        lhs.messages == rhs.messages && lhs.nicks == rhs.nicks && lhs.roles == rhs.roles && lhs.avatars == rhs.avatars && lhs.pronouns == rhs.pronouns
    }

    @Published var messages: [Message] = .init()
    @Published var nicks: [String: String] = .init()
    @Published var roles: [String: String] = .init()
    @Published var avatars: [String: String] = .init()
    @Published var pronouns: [String: String] = .init()
    var cancellable: Set<AnyCancellable> = .init()
    var permissions: Permissions = .init()
    
    var guildID: String
    var channelID: String
    
    static var permissionQueue = DispatchQueue(label: "red.evelyn.AccordPermissionQueue")

    init(channel: Channel) {
        self.channelID = channel.id
        self.guildID = channel.guild_id ?? "@me"
        guard wss != nil else { return }
        messageFetchQueue.async {
            if self.guildID == "@me" {
                try? wss.subscribeToDM(self.channelID)
            } else {
                try? wss.subscribe(to: self.guildID)
            }
            self.getMessages(channelID: self.channelID, guildID: self.guildID)
            MentionSender.shared.removeMentions(server: self.guildID)
            if self.guildID == "@me" {
                self.permissions = .init([
                    .sendMessages, .readMessages
                ])
                if channel.owner_id == user_id {
                    self.permissions.insert(.kickMembers)
                }
            } else {
                Self.permissionQueue.async {
                    self.permissions = channel.permission_overwrites?.allAllowed(guildID: self.guildID) ?? .init()
                    print(self.permissions.contains(.sendMessages))
                }
            }
        }
        connect()
    }

    func connect() {
        wss.messageSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg, channelID, _ in
                assert(!Thread.isMainThread)
                guard channelID == self?.channelID else { return }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
                guard let message = try? decoder.decode(GatewayMessage.self, from: msg).d else { return }
                message.processedTimestamp = message.timestamp.makeProperDate()
                message.user_mentioned = message.mentions.compactMap { $0?.id }.contains(user_id)
                if self?.guildID != "@me", !(self?.roles.keys.contains(message.author?.id ?? "") ?? false) {
                    self?.loadUser(for: message.author?.id)
                }
                if let firstMessage = self?.messages.first {
                    message.sameAuthor = firstMessage.author?.id == message.author?.id
                }
                DispatchQueue.main.async {
                    if let count = self?.messages.count, count == 50 {
                        self?.messages.removeLast()
                    }
                    guard let author = message.author else { return }
                    Storage.usernames[author.id] = author.username
                    withAnimation(Animation.linear(duration: 0.1)) {
                        self?.messages.insert(message, at: 0)
                    }
                }
            }
            .store(in: &cancellable)
        wss.memberChunkSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg in
                assert(!Thread.isMainThread)
                guard let chunk = try? JSONDecoder().decode(GuildMemberChunkResponse.self, from: msg), let users = chunk.d?.members else { return }
                let allUsers: [GuildMember] = users.compactMap { $0 }
                for person in allUsers {
                    DispatchQueue.main.async {
                        wss.cachedMemberRequest["\(self?.guildID ?? "")$\(person.user.id)"] = person
                        if let nickname = person.nick {
                            self?.nicks[person.user.id] = nickname
                        }
                        if let avatar = person.avatar {
                            self?.avatars[person.user.id] = avatar
                        }
                    }
                    if let roles = person.roles {
                        let temp = roles
                            .filter { roleColors[$0] != nil }
                            .sorted(by: { roleColors[$0]!.1 > roleColors[$1]!.1 })
                        if let foregroundRoleColor = temp.first {
                            DispatchQueue.main.async {
                                self?.roles[person.user.id] = foregroundRoleColor
                            }
                        }
                    }
                }
            }
            .store(in: &cancellable)
        wss.deleteSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg, channelID in
                assert(!Thread.isMainThread)
                guard channelID == self?.channelID else { return }
                let messageMap = self?.messages.generateKeyMap()
                guard let gatewayMessage = try? JSONDecoder().decode(GatewayDeletedMessage.self, from: msg) else { return }
                guard let message = gatewayMessage.d else { return }
                guard let index = messageMap?[message.id] else { return }
                DispatchQueue.main.async {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        let i: Int = index
                        self?.messages.remove(at: i)
                    }
                }
            }
            .store(in: &cancellable)
        wss.editSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg, channelID in
                assert(!Thread.isMainThread)
                // Received a message from backend
                guard channelID == self?.channelID else { return }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
                guard let message = try? decoder.decode(GatewayMessage.self, from: msg).d else { return }
                message.processedTimestamp = message.timestamp.makeProperDate()
                message.user_mentioned = message.mentions.compactMap { $0?.id }.contains(user_id)
                let messageMap = self?.messages.generateKeyMap()
                DispatchQueue.main.async {
                    self?.messages[keyed: message.id, messageMap] = message
                }
            }
            .store(in: &cancellable)
    }

    func ack(channelID: String, guildID: String) {
        guard let last = messages.first?.id else { return }
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(last)/ack"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            bodyObject: ["token": NSNull()], // I don't understand why this is needed, but it wasn't when I first implemented ack...
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)",
            json: true
        ))
    }

    func getMessages(channelID: String, guildID: String) {
        RequestPublisher.fetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
        .subscribe(on: DispatchQueue.global(qos: .userInitiated))
        .receive(on: DispatchQueue.global(qos: .userInitiated))
        .map { output -> [Message] in
            output.enumerated().compactMap { index, element -> Message in
                guard element != output.last else { return element }
                element.processedTimestamp = element.timestamp.makeProperDate()
                element.sameAuthor = output[index + 1].author?.id == element.author?.id
                element.user_mentioned = element.mentions.compactMap { $0?.id }.contains(user_id)
                return element
            }
        }
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case let .failure(error):
                print(error)
                MentionSender.shared.deselect()
            }
        }) { [weak self] messages in
            self?.messages = messages
            DispatchQueue.global(qos: .userInitiated).async {
                guildID == "@me" ? self?.fakeNicksObject() : self?.performSecondStageLoad()
                self?.loadPronouns()
                self?.ack(channelID: channelID, guildID: guildID)
                self?.cacheUsernames()
            }
        }
        .store(in: &cancellable)
    }

    func cacheUsernames() {
        messages.forEach { message in
            guard let author = message.author else { return }
            Storage.usernames[author.id] = author.username
        }
    }

    func loadUser(for id: String?) {
        guard let id = id else { return }
        guard let person = wss.cachedMemberRequest["\(guildID)$\(id)"] else {
            try? wss.getMembers(ids: [id], guild: guildID)
            return
        }
        let nickname = person.nick ?? person.user.username
        DispatchQueue.main.async {
            self.nicks[person.user.id] = nickname
        }
        if let avatar = person.avatar {
            avatars[person.user.id] = avatar
        }
        if let roles = person.roles {
            let temp = roles
                .filter { roleColors[$0] != nil }
                .sorted(by: { roleColors[$0]!.1 > roleColors[$1]!.1 })
            if let foregroundRoleColor = temp.first {
                DispatchQueue.main.async {
                    self.roles[person.user.id] = foregroundRoleColor
                }
            }
        }
    }

    func fakeNicksObject() {
        guard guildID == "@me" else { return }
        let _nicks: [String: String] = messages.compactMap { [$0.author?.id ?? "": $0.author?.username ?? ""] }
            .flatMap { $0 }
            .reduce([String: String]()) { dict, tuple in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            }
        DispatchQueue.main.async {
            self.nicks = _nicks
        }
    }

    func loadPronouns() {
        guard AccordCoreVars.pronounDB else { return }
        RequestPublisher.fetch([String: String].self, url: URL(string: "https://pronoundb.org/api/v1/lookup-bulk"), headers: Headers(
            bodyObject: [
                "platform": "discord",
                "ids": messages.compactMap { $0.author?.id }.joined(separator: ","),
            ],
            type: .GET
        ))
        .replaceError(with: [:])
        .receive(on: DispatchQueue.main)
        .sink { [weak self] value in
            self?.pronouns = value.mapValues {
                pronounDBFormed(pronoun: $0)
            }
        }
        .store(in: &cancellable)
    }

    func getCachedMemberChunk() {
        let allUserIDs = messages.compactMap { $0.author?.id }
            .removingDuplicates()
        for person in allUserIDs.compactMap({ wss.cachedMemberRequest["\(guildID)$\($0)"] }) {
            let nickname = person.nick ?? person.user.username
            DispatchQueue.main.async {
                self.nicks[person.user.id] = nickname
            }
            if let avatar = person.avatar {
                avatars[person.user.id] = avatar
            }
            if let roles = person.roles {
                let temp = roles
                    .filter { roleColors[$0] != nil }
                    .sorted(by: { roleColors[$0]!.1 > roleColors[$1]!.1 })
                if let foregroundRoleColor = temp.first {
                    DispatchQueue.main.async {
                        self.roles[person.user.id] = foregroundRoleColor
                    }
                }
            }
        }
    }

    func performSecondStageLoad() {
        var allUserIDs: [String] = Array(NSOrderedSet(array: messages.compactMap { $0.author?.id })) as! [String]
        // getCachedMemberChunk()
        for (index, item) in allUserIDs.enumerated() {
            if Array(wss.cachedMemberRequest.keys).contains("\(guildID)$\(item)"), [Int](allUserIDs.indices).contains(index) {
                allUserIDs.remove(at: index)
            }
        }
        if !(allUserIDs.isEmpty) {
            try? wss.getMembers(ids: allUserIDs, guild: guildID)
        }
    }

    func loadMoreMessages() {
        RequestPublisher.fetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/messages?before=\(messages.last?.id ?? "")&limit=50"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
        .sink(receiveCompletion: { _ in

        }) { [weak self] msg in
            let messages: [Message] = msg.enumerated().compactMap { index, element -> Message in
                guard element != msg.last else { return element }
                element.processedTimestamp = element.timestamp.makeProperDate()
                element.sameAuthor = msg[index + 1].author?.id == element.author?.id
                element.user_mentioned = element.mentions.compactMap { $0?.id }.contains(user_id)
                return element
            }
            self?.messages.append(contentsOf: messages)
        }
        .store(in: &cancellable)
    }
}

extension Array where Array.Element: Hashable {
    func unique() -> some Collection {
        Array(Set(self))
    }
}

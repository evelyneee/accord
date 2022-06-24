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
    @MainActor static func == (lhs: ChannelViewViewModel, rhs: ChannelViewViewModel) -> Bool {
        lhs.messages == rhs.messages &&
            lhs.nicks == rhs.nicks &&
            lhs.roles == rhs.roles &&
            lhs.avatars == rhs.avatars &&
            lhs.pronouns == rhs.pronouns
    }

    @MainActor @Published
    var messages: [Message] = .init()
    
    @MainActor @Published
    var nicks: [String: String] = .init()
    
    @MainActor @Published
    var roles: [String: String] = .init()
    
    @MainActor @Published
    var avatars: [String: String] = .init()
    
    @MainActor @Published
    var pronouns: [String: String] = .init()

    @MainActor @Published
    var memberList: [OPSItems] = .init()
    
    @MainActor @Published
    var typing: [String] = .init()

    var cancellable: Set<AnyCancellable> = .init()
    
    @MainActor @Published
    var permissions: Permissions = .init()
    
    @Published var noMoreMessages = false

    @Environment(\.user)
    var user: User

    var guildID: String
    var channelID: String

    static var permissionQueue = DispatchQueue(label: "red.evelyn.AccordPermissionQueue")

    fileprivate static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
        return decoder
    }()

    let channel: Channel
    
    init(channel: Channel) {
        self.channel = channel
        channelID = channel.id
        guildID = channel.guild_id ?? "@me"
        guard wss != nil else { return }
        connect()
        loadChannel(channel)
    }
    
    @MainActor
    func setPermissions(_ model: AppGlobals) async {
        if !(guildID == "@me" || self.channel.overridePermissions == true) {
            let perms = model.permissionsAllowed(self.channel.permission_overwrites ?? [], guildID: self.guildID)
            await MainActor.run {
                self.permissions = perms
            }
        }
    }

    func loadChannel(_ channel: Channel) {
        messageFetchQueue.async { [weak self] in
            guard let self = self else { return }
            if self.guildID == "@me" {
                try? wss.subscribeToDM(self.channelID)
            } else {
                try? wss.subscribe(to: self.guildID)
            }
            self.loadPermissions(channel)
            self.getMessages(channelID: self.channelID, guildID: self.guildID)
            MentionSender.shared.removeMentions(server: self.guildID)
        }
    }

    func loadPermissions(_ channel: Channel) {
        if guildID == "@me" || channel.overridePermissions == true {
            DispatchQueue.main.async {
                self.permissions = .init([
                    .sendMessages, .readMessages,
                ])
                if channel.owner_id == user_id {
                    self.permissions.insert(.kickMembers)
                }
            }
        }
    }

    private static var cachingQueue = DispatchQueue(label: "red.evelyn.accord.CachingQueue", attributes: .concurrent)
    private func cacheUsers(_ members: [GuildMember]) {
        Self.cachingQueue.async { [weak self] in
            guard let guildID = self?.guildID else { return }
            members.forEach { user in
                do {
                    let saving = GuildMember.GuildMemberSaved(member: user)
                    let data = try JSONEncoder().encode(saving)
                    guard let url = URL(string: rootURL)?
                        .appendingPathComponent("guilds")
                        .appendingPathComponent(guildID)
                        .appendingPathComponent("members")
                        .appendingPathComponent(user.user.id) else { return }
                    let request = URLRequest(url: url)
                    let response = URLResponse(url: url, mimeType: "application/discord-guild-member", expectedContentLength: data.count, textEncodingName: "utf8")
                    let fakeURLResponse = CachedURLResponse(response: response, data: data)
                    cache.storeCachedResponse(fakeURLResponse, for: request)
                } catch { print(error) }
            }
        }
    }

    func loadCachedUser(_ id: String) throws -> GuildMember {
        assert(!Thread.isMainThread)
        guard let url = URL(string: rootURL)?
            .appendingPathComponent("guilds")
            .appendingPathComponent(guildID)
            .appendingPathComponent("members")
            .appendingPathComponent(id) else { throw "Bad url" }
        let request = URLRequest(url: url)
        guard let user = cache.cachedResponse(for: request) else { throw "No user data" }
        let cachedObject = try JSONDecoder().decode(GuildMember.GuildMemberSaved.self, from: user.data)
        guard !cachedObject.isOutdated else { throw "Outdated object" }
        return cachedObject.member
    }

    func connect() {
        wss.messageSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg, channelID, _ in
                guard let self = self, channelID == self.channelID else { return }
                Task.detached {
                    guard var message = try? Self.decoder.decode(GatewayMessage.self, from: msg).d else { return }
                    message.processedTimestamp = message.timestamp.makeProperDate()
                    message.user_mentioned = message.mentions.map(\.id).contains(user_id)
                    if self.guildID != "@me", await !(self.roles.keys.contains(message.author?.id ?? "") ) {
                        self.loadUser(for: message.author?.id)
                    }
                    if let firstMessage = await self.messages.first {
                        message.sameAuthor = firstMessage.author?.id == message.author?.id
                    }
                    if let count = await self.messages.count, count == 50 {
                        _ = await MainActor.run {
                            self.messages.removeLast()
                        }
                    }
                    guard let author = message.author else { return }
                    await MainActor.run {
                        Storage.users[author.id] = author
                    }
                    withAnimation(Animation.easeInOut(duration: 0.05)) {
                        let message = message
                        Task {
                            await MainActor.run {
                                self.messages.insert(message, at: 0)
                            }
                        }
                    }
                }
            }
            .store(in: &cancellable)

        wss.memberChunkSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg in
                guard let chunk = try? JSONDecoder().decode(GuildMemberChunkResponse.self, from: msg),
                      let users = chunk.d?.members,
                      chunk.d?.guild_id == self?.guildID else { return }
                let allUsers: [GuildMember] = users.compactMap { $0 }
                self?.cacheUsers(allUsers)
                for person in allUsers {
                    self?.memberLoad(person)
                }
            }
            .store(in: &cancellable)

        wss.deleteSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg, channelID in
                guard let self = self, channelID == self.channelID else { return }
                Task.detached {
                    let messageMap = await self.messages.generateKeyMap()
                    guard let gatewayMessage = try? JSONDecoder().decode(GatewayDeletedMessage.self, from: msg),
                          let message = gatewayMessage.d,
                          let index = messageMap[message.id] else { return }
                    await MainActor.run {
                        withAnimation(Animation.easeInOut(duration: 0.05)) {
                            let i: Int = index
                            self.messages.remove(at: i)
                        }
                    }
                }
            }
            .store(in: &cancellable)

        wss.editSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg, channelID in
                // Received a message from backend
                guard let self = self, channelID == self.channelID else { return }
                Task.detached {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
                    guard var message = try? decoder.decode(GatewayMessage.self, from: msg).d else { return }
                    message.processedTimestamp = message.timestamp.makeProperDate()
                    message.user_mentioned = message.mentions.map(\.id).contains(user_id)
                    let messageMap = await self.messages.generateKeyMap()
                    let message = message
                    await MainActor.run {
                        guard let index = messageMap[message.id] else { return }
                        self.setMessage(index, message)
                    }
                }
            }
            .store(in: &cancellable)

        wss.typingSubject
            .receive(on: webSocketQueue)
            .sink { [weak self] msg, channelID in

                guard let self = self, channelID == self.channelID,
                      let memberDecodable = try? JSONDecoder().decode(TypingEvent.self, from: msg).d,
                      memberDecodable.user_id != self.user.id else { return }
                Task.detached {
                    let isKnownAs =
                        await self.nicks[memberDecodable.user_id] ??
                        memberDecodable.member?.nick ??
                        memberDecodable.member?.user.username ??
                        "Unknown User"

                    DispatchQueue.main.async {
                        if self.typing.contains(isKnownAs) == false {
                            self.typing.append(isKnownAs)
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                        guard self?.typing.isEmpty == false else { return }
                        self?.typing.removeLast()
                    }
                }
            }
            .store(in: &cancellable)
        wss.memberListSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] list in
                guard let self = self else { return }
                Task.detached {
                    if await self.memberList.isEmpty {
                        let list = Array(list.d.ops.compactMap(\.items).joined())
                            .map { item -> OPSItems in
                                let new = item
                                new.member?.roles = new.member?.roles?
                                    .compactMap { id -> (String, (Int, Int))? in
                                        if let color = Storage.roleColors[id] {
                                            return (id, color)
                                        }
                                        return nil
                                    }
                                    .sorted(by: { $0.1.1 > $1.1.1 })
                                    .map(\.0)
                                return new
                            }
                        await MainActor.run {
                            self.memberList = list
                        }
                    }
                }
            }
            .store(in: &cancellable)
    }
    
    @MainActor func setMessage(_ idx: Int, _ message: Message) {
        self.messages[idx] = message
    }

    private func memberLoad(_ person: GuildMember) {
        DispatchQueue.main.async {
            if let nickname = person.nick {
                self.nicks[person.user.id] = nickname
            }
            if let avatar = person.avatar {
                self.avatars[person.user.id] = avatar
            }
        }
        if let roles = person.roles {
            let foregroundRoleColor = roles
                .compactMap { id -> (String, (Int, Int))? in
                    if let color = Storage.roleColors[id] {
                        return (id, color)
                    }
                    return nil
                }
                .sorted(by: { $0.1.1 > $1.1.1 })
                .map(\.0).first
            if let foregroundRoleColor = foregroundRoleColor {
                DispatchQueue.main.async {
                    self.roles[person.user.id] = foregroundRoleColor
                }
            }
        }
    }

    func ack(channelID: String, guildID: String) async {
        guard let last = await messages.first?.id else { return }
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(last)/ack"), headers: Headers(
            token: Globals.token,
            bodyObject: ["token": NSNull()], // I don't understand why this is needed, but it wasn't when I first implemented ack...
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)",
            json: true
        ))
    }

    func getMessages(channelID: String, guildID: String, scrollAfter: Bool = false) {
        RequestPublisher.fetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
            token: Globals.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
        .subscribe(on: messageFetchQueue)
        .receive(on: messageFetchQueue)
        .map { output -> [Message] in
            output.enumerated().compactMap { index, element -> Message in
                guard element != output.last else { return element }
                var element = element
                element.processedTimestamp = element.timestamp.makeProperDate()
                element._inSameDay = Calendar.current.isDate(element.timestamp, inSameDayAs: output[index + 1].timestamp)
                element.sameAuthor = output[index + 1].author?.id == element.author?.id
                element.user_mentioned = element.mentions.map(\.id).contains(user_id)
                return element
            }
        }
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case let .failure(error):
                print(error)
                MentionSender.shared.deselect()
            }
        }) { [weak self] messages in
            guard let self = self else { return }
            Task {
                await MainActor.run {
                    self.messages = messages
                }
                if messages.count < 50 {
                    self.noMoreMessages = true
                }
                if scrollAfter {
                    let channelID = self.channelID
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        ChannelView.scrollTo.send((channelID, messages.first?.id ?? ""))
                    })
                }
                Task.detached {
                    guildID == "@me" ? await self.fakeNicksObject() : await self.performSecondStageLoad()
                    await self.loadPronouns()
                    await self.ack(channelID: channelID, guildID: guildID)
                    await self.cacheUsernames()
                }
            }
        }
        .store(in: &cancellable)
    }

    func cacheUsernames() async {
        await self.messages.forEach { message in
            guard let author = message.author else { return }
            DispatchQueue.main.async {
                Storage.users[author.id] = author
            }
        }
    }

    func loadUser(for id: String?) {
        guard let id = id else { return }
        guard let person = try? loadCachedUser(id) else {
            try? wss.getMembers(ids: [id], guild: guildID)
            return
        }
        memberLoad(person)
    }

    func fakeNicksObject() async {
        guard guildID == "@me" else { return }
        let _nicks: [String: String] = await messages
            .compactMap { [$0.author?.id ?? "": $0.author?.username ?? ""] }
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

    func loadPronouns() async {
        guard Globals.pronounDB else { return }
        await RequestPublisher.fetch([String: String].self, url: URL(string: "https://pronoundb.org/api/v1/lookup-bulk"), headers: Headers(
            bodyObject: [
                "platform": "discord",
                "ids": messages.compactMap { $0.author?.id }.joined(separator: ","),
            ],
            type: .GET
        ))
        .replaceError(with: [:])
        .sink { [weak self] value in
            guard let self = self else { return }
            Task {
                await MainActor.run {
                    self.pronouns = value.mapValues {
                        pronounDBFormed(pronoun: $0)
                    }
                }
            }
        }
        .store(in: &cancellable)
    }

    func performSecondStageLoad() async {
        var allUserIDs: [String] = await messages
            .compactMap { $0.author?.id }
            .removingDuplicates()
        var toRemove: [String] = .init()
        allUserIDs.forEach { id in
            do {
                let member = try self.loadCachedUser(id)
                toRemove.append(id)
                memberLoad(member)
            } catch { print(error) }
        }
        allUserIDs = allUserIDs.filter { !toRemove.contains($0) }
        if !(allUserIDs.isEmpty) {
            print(allUserIDs, "websocket request")
            try? wss.getMembers(ids: allUserIDs, guild: guildID)
        }
    }

    func loadMoreMessages() async {
        let url = await root
            .appendingPathComponent("channels")
            .appendingPathComponent(channelID)
            .appendingPathComponent("messages")
            .appendingQueryParameters([
                "before":messages.last?.id ?? "",
                "limit":"50"
            ])
        RequestPublisher.fetch([Message].self, url: url, headers: Headers(
            token: Globals.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
        .map { msg in
            msg.enumerated().compactMap { index, element -> Message in
                guard element != msg.last else { return element }
                var element = element
                element.processedTimestamp = element.timestamp.makeProperDate()
                element._inSameDay = Calendar.current.isDate(element.timestamp, inSameDayAs: msg[index + 1].timestamp)
                element.sameAuthor = msg[index + 1].author?.id == element.author?.id
                element.user_mentioned = element.mentions.map(\.id).contains(user_id)
                return element
            }
        }
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { _ in

        }) { [weak self] messages in
            if messages.isEmpty {
                self?.noMoreMessages = true
            }
            guard let self = self else { return }
            Task {
                await MainActor.run {
                    self.messages.append(contentsOf: messages)
                }
            }
        }
        .store(in: &cancellable)
    }

    func loadAroundMessage(id: String) {
        let url = root
            .appendingPathComponent("channels")
            .appendingPathComponent(channelID)
            .appendingPathComponent("messages")
            .appendingQueryParameters([
                "around":id,
                "limit":"50"
            ])
        RequestPublisher.fetch([Message].self, url: url, headers: Headers(
            token: Globals.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
        .map { msg in
            msg.enumerated().compactMap { index, element -> Message in
                guard element != msg.last else { return element }
                var element = element
                element.processedTimestamp = element.timestamp.makeProperDate()
                element._inSameDay = Calendar.current.isDate(element.timestamp, inSameDayAs: msg[index + 1].timestamp)
                element.sameAuthor = msg[index + 1].author?.id == element.author?.id
                element.user_mentioned = element.mentions.map(\.id).contains(user_id)
                return element
            }
        }
        .receive(on: RunLoop.main)
        .replaceError(with: [])
        .map { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                ChannelView.scrollTo.send((self?.channelID ?? "", id))
            }
            return $0
        }
        .assign(to: &self.$messages)
    }
}

extension Array where Array.Element: Hashable {
    func unique() -> some Collection {
        Array(Set(self))
    }
}

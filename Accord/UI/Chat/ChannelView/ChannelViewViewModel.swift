//
//  ChannelViewViewModel.swift
//  Accord
//
//  Created by evelyn on 2021-10-22.
//

import Foundation
import AppKit
import Combine
import SwiftUI

final class ChannelViewViewModel: ObservableObject {

    #if DEBUG
    internal static let developingOffline: Bool = false
    #endif

    @Published var messages = [Message]()
    @Published var nicks: [String: String] = [:]
    @Published var roles: [String: String] = [:]
    @Published var pronouns: [String: String] = [:]
    var cancellable = Set<AnyCancellable>()

    var offset: Float = 0

    var guildID: String
    var channelID: String

    // save scrollview so we can scroll programmatically the good way
    weak var scrollView: NSScrollView?

    init(channelID: String, guildID: String) {
        self.channelID = channelID
        self.guildID = guildID
        messageFetchQueue.async { [weak self] in
            self?.guildID == "@me" ? wss.subscribeToDM(channelID) : wss.subscribe(guildID, channelID)
            MentionSender.shared.removeMentions(server: guildID)
            // fetch messages
            self?.getMessages(channelID: channelID, guildID: guildID)
        }
    }

    func ack(channelID: String, guildID: String) {
        guard let last = messages.last?.id else { return }
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(last)/ack"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            bodyObject: ["token":NSNull()], // I don't understand why this is needed, but it wasn't when I first implemented ack...
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)",
            json: true
        ))
    }

    func scrollTo(_ index: Int) {
        guard let scrollView = scrollView else { return }
        guard let height = scrollView.documentView?.bounds.height else { print("no position"); return }
        scrollView.documentView?.scroll(NSPoint(x: 0, y: Int(height) / self.messages.count * index))
    }

    func getMessages(channelID: String, guildID: String) {
        #if DEBUG
        guard !ChannelViewViewModel.developingOffline else {
            self.offlineMessages()
            return
        }
        #endif
        RequestPublisher.fetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
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
        }) { msg in
            let messages: [Message] = msg.enumerated().compactMap { (index, element) -> Message in
                guard element != msg.last else { return element }
                element.lastMessage = msg[index + 1]
                return element
            }
            DispatchQueue.main.async { [weak self] in
                self?.messages = messages.reversed()
                messageFetchQueue.async {
                    guildID == "@me" ? self?.fakeNicksObject() : self?.performSecondStageLoad()
                    self?.loadPronouns()
                    self?.ack(channelID: channelID, guildID: guildID)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    AppKitLink<NSScrollView>.introspect { scrollView, count in
                        if let documentView = scrollView.documentView, count == 4 {
                            Swift.print("[AppKitLink] Successfully found \(type(of: scrollView))")
                            self?.scrollView = scrollView
                            documentView.scroll(NSPoint(x: 0, y: documentView.bounds.size.height))
                        }
                    }
                })
            }
        }
        .store(in: &cancellable)
    }

    #if DEBUG
    func offlineMessages() {
    }
    #endif

    func loadUser(for id: String?) {
        guard let id = id else { return }
        guard let person = wss.cachedMemberRequest["\(guildID)$\(id)"] else {
            try? wss.getMembers(ids: [id], guild: guildID)
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
            let temp: [String] = rolesTemp.compactMap { $0 }.reversed()
            if !(temp.isEmpty) {
                DispatchQueue.main.async {
                    self.roles[(person.user.id)] = temp[0]
                }
            }
        }
    }

    func fakeNicksObject() {
        guard self.guildID == "@me" else { return }
        let _nicks: [String: String] = messages.compactMap { [ $0.author?.id ?? "": $0.author?.username ?? "" ] }
        .flatMap { $0 }
        .reduce([String: String]()) { (dict, tuple) in
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
            bodyObject: ["platform": "discord", "ids": messages.compactMap({ $0.author?.id}).joined(separator: ",")],
            type: .GET
        ))
        .replaceError(with: [:])
        .sink { value in
            var value = value
            for key in value.keys {
                pronounDBFormed(pronoun: &value[key])
            }
            DispatchQueue.main.async {
                self.pronouns = value
            }
        }
        .store(in: &cancellable)
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
                let temp: [String] = rolesTemp.compactMap { $0 }.reversed()
                DispatchQueue.main.asyncIf(temp.isEmpty) {
                    self.roles[(person.user.id)] = temp[safe: 0]
                }
            }
        }
    }

    func performSecondStageLoad() {
        var allUserIDs: [String] = Array(NSOrderedSet(array: messages.compactMap { $0.author?.id })) as! [String]
        getCachedMemberChunk()
        for (index, item) in allUserIDs.enumerated {
            if Array(wss.cachedMemberRequest.keys).contains("\(guildID)$\(item)") && [Int](allUserIDs.indices).contains(index) {
                allUserIDs.remove(at: index)
            }
        }
        if !(allUserIDs.isEmpty) {
            print(allUserIDs)
            try? wss.getMembers(ids: allUserIDs, guild: guildID)
        }
    }
    deinit {
        print("Closing \(channelID)")
        cancellable.forEach { $0.cancel() }
        ChannelMembers.shared.channelMembers = [:]
    }
}

extension Array where Array.Element: Hashable {
    func unique() -> some Collection {
        return Array(Set(self))
    }
}

extension Array {
    var enumerated: EnumeratedSequence<[Element]> {
        return self.enumerated()
    }
}

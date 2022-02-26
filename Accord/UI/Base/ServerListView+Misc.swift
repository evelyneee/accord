//
//  ServerListView+Misc.swift
//  ServerListView+Misc
//
//  Created by evelyn on 2021-09-12.
//

import Foundation

extension ServerListView {
    static func fastIndexGuild(_ guild: String, array: [Guild]) -> Int? {
        let messageDict = array.generateKeyMap()
        return messageDict[guild]
    }

    func fastIndexChannels(_ channel: String, array: [Channel]) -> Int? {
        let messageDict = array.generateKeyMap()
        return messageDict[channel]
    }

    func fastIndexEntries(_ entry: String, array: [ReadStateEntry]) -> Int? {
        let messageDict = array.generateKeyMap()
        return messageDict[entry]
    }

    func assignPrivateReadStates() {
        let privateReadStateDict = Self.readStates.generateKeyMap()
        for (i, channel) in Self.privateChannels.enumerated() {
            if let index = privateReadStateDict[channel.id] {
                Self.privateChannels[i].read_state = Self.readStates[index]
            }
        }
        print("Binded to private channels")
        Self.readStates.removeAll()
    }
}

extension GatewayD {
    func order() {
        self.guilds.enumerated().forEach { index, _guild in
            var guild = _guild
            guild.channels = guild.channels?.sorted { ($0.type.rawValue, $0.position ?? 0, $0.id) < ($1.type.rawValue, $1.position ?? 0, $1.id) }
            guard let rejects = guild.channels?
                    .filter({ $0.parent_id == nil && $0.type != .section }),
                  let parents: [Channel] = guild.channels?.filter({ $0.type == .section }),
                  let sections = Array(NSOrderedSet(array: parents)) as? [Channel] else { return }
            var sectionFormatted: [Channel] = .init()
            sections.forEach { channel in
                guard let matching = guild.channels?.filter({ $0.parent_id == channel.id }), !matching.isEmpty else { return }
                sectionFormatted.append(channel)
                sectionFormatted.append(contentsOf: matching)
            }
            var threadFormatted: [Channel] = .init()
            sectionFormatted.forEach { channel in
                guard let matching = guild.threads?.filter({ $0.parent_id == channel.id }) else { return }
                threadFormatted.append(channel)
                threadFormatted.append(contentsOf: matching)
            }
            threadFormatted.insert(contentsOf: rejects, at: 0)
            guild.channels = threadFormatted
            self.guilds[index] = guild
        }
    }

    func assignReadStates() {
        guard let readState = self.read_state else { return }
        let stateDict = readState.entries.generateKeyMap()
        self.guilds.enumerated().forEach { index, guild in
            var guild = guild
            guard var channels = guild.channels else { return }
            var temp: [Channel] = .init()
            for (index, channel) in channels.enumerated() {
                guard channel.type == .normal ||
                        channel.type == .dm ||
                        channel.type == .group_dm ||
                        channel.type == .guild_news ||
                        channel.type == .guild_private_thread ||
                        channel.type == .guild_private_thread else {
                            temp.append(channel)
                            continue
                }
                guard let at = stateDict[channel.id] else {
                    continue
                }
                channels[index].read_state = readState.entries[at]
                temp.append(channels[index])
            }
            guild.channels = temp
            self.guilds[index] = guild
        }
        print("Binded to guild channels")
    }
}

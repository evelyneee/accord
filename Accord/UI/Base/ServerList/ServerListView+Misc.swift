//
//  ServerListView+Misc.swift
//  ServerListView+Misc
//
//  Created by evelyn on 2021-09-12.
//

import Foundation

extension ServerListView {
    static func fastIndexGuild(_ guild: String, array: [Guild]) -> Int? {
        array[indexOf: guild]
    }

    func fastIndexChannels(_ channel: String, array: [Channel]) -> Int? {
        array[indexOf: channel]
    }

    func fastIndexEntries(_ entry: String, array: [ReadStateEntry]) -> Int? {
        array[indexOf: entry]
    }

    func assignPrivateReadStates(_ entries: [ReadStateEntry]) {
        let privateReadStateDict = entries.generateKeyMap()
        Self.privateChannels.enumerated().forEach {
            Self.privateChannels[$0].read_state = entries[keyed: $1.id, privateReadStateDict]
        }
        print("Binded to private channels")
        Self.readStates.removeAll()
    }
}

extension GatewayD {
    func order() {
        let showHiddenChannels = UserDefaults.standard.bool(forKey: "ShowHiddenChannels")
        guilds.enumerated().forEach { index, _guild in
            var guild = _guild
            guild.channels = guild.channels.sorted { ($0.type.rawValue, $0.position ?? 0, $0.id) < ($1.type.rawValue, $1.position ?? 0, $1.id) }
            guard let sections = Array(NSOrderedSet(array: guild.channels.filter({ $0.type == .section }))) as? [Channel] else { return }
            let rejects = guild.channels
                .filter({ $0.parent_id == nil && $0.type != .section })
            var sectionFormatted: [Channel] = .init()
            sections.forEach { channel in
                let matching = guild.channels
                    .filter({ $0.parent_id == channel.id })
                    .filter({ showHiddenChannels ? true : ($0.shown ?? true) })
                guard !matching.isEmpty else { return }
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
        guard let readState = read_state else { return }
        let stateDict = readState.entries.generateKeyMap()
        guilds.enumerated().forEach { (index, guild) -> Void in
            var guild = guild
            var channels = guild.channels
            channels = channels.map { channel -> Channel in
                var channel = channel
                channel.guild_id = guild.id
                channel.shown = channel.hasPermission(.readMessages)
                return channel
            }
            for (index, channel) in channels.enumerated() {
                guard channel.type == .normal ||
                    channel.type == .dm ||
                    channel.type == .group_dm ||
                    channel.type == .guild_news ||
                    channel.type == .guild_private_thread ||
                    channel.type == .guild_private_thread
                else {
                    continue
                }
                channels[index].read_state = readState.entries[keyed: channel.id, stateDict]
            }
            guild.channels = channels
            self.guilds[index] = guild
        }
        print("Binded to guild channels")
    }
}

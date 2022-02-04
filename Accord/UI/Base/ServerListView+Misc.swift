//
//  ServerListView+Misc.swift
//  ServerListView+Misc
//
//  Created by evelyn on 2021-09-12.
//

import Foundation

extension ServerListView {
    static func fastIndexGuild(_ guild: String, array: [Guild]) -> Int? {
        let messageDict = array.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        }
        return messageDict[guild]
    }

    func fastIndexChannels(_ channel: String, array: [Channel]) -> Int? {
        let messageDict = array.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        }
        return messageDict[channel]
    }

    func fastIndexEntries(_ entry: String, array: [ReadStateEntry]) -> Int? {
        let messageDict = array.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        }
        return messageDict[entry]
    }

    func order(full: inout GatewayD?) {
        for (index, _guild) in (full?.guilds ?? []).enumerated() {
            var guild = _guild
            let rejects = guild.channels?.filter { $0.parent_id == nil && $0.type != .section }
            guild.channels = guild.channels?.sorted(by: { $1.position ?? 0 > $0.position ?? 0 })
            let parents: [Channel] = guild.channels?.filter { $0.type == .section } ?? []
            let ids = Array(NSOrderedSet(array: parents)) as? [Channel] ?? []
            var ret = [Channel]()
            for id in ids {
                let matching = guild.channels?.filter { $0.parent_id == id.id }
                ret.append(id)
                ret.append(contentsOf: matching ?? [])
            }
            ret.insert(contentsOf: rejects ?? [], at: 0)
            guild.channels = ret
            full?.guilds[index] = guild
        }
        for (index, _guild) in (full?.guilds ?? []).enumerated() {
            var guild = _guild
            let ids = Array(NSOrderedSet(array: guild.channels ?? [])) as? [Channel] ?? []
            var ret = [Channel]()
            for id in ids {
                let matching = guild.threads?.filter { $0.parent_id == id.id }
                ret.append(id)
                ret.append(contentsOf: matching ?? [])
            }
            guild.channels = ret
            full?.guilds[index] = guild
        }
    }

    func assignReadStates(full: inout GatewayD?) {
        guard let readState = full?.read_state else { return }
        let stateDict = readState.entries.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        }
        for folder in Self.folders {
            for (index, guild) in folder.guilds.enumerated() {
                var guild = guild
                guard var channels = guild.channels else { return }
                var temp = [Channel]()
                for (index, channel) in channels.enumerated() {
                    guard channel.type == .normal || channel.type == .dm || channel.type == .group_dm else {
                        temp.append(channel)
                        continue
                    }
                    guard let at = stateDict[channel.id] else {
                        continue
                    }
                    channels[index].read_state = readState.entries[at]
                    temp.append(channel)
                }
                guild.channels = temp
                folder.guilds[index] = guild
            }
        }
        print("Binded to guild channels")
    }

    func assignPrivateReadStates() {
        let messageDict = Self.readStates.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        }
        for (i, channel) in Self.privateChannels.enumerated() {
            if let index = messageDict[channel.id] {
                Self.privateChannels[i].read_state = Self.readStates[index]
            }
        }
        print("Binded to private channel")
        Self.readStates.removeAll()
    }
}

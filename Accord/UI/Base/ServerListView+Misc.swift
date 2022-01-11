//
//  ServerListView+Misc.swift
//  ServerListView+Misc
//
//  Created by evelyn on 2021-09-12.
//

import Foundation

extension ServerListView {
    static func fastIndexGuild(_ guild: String, array: [Guild]) -> Int? {
        let messageDict = array.enumerated().compactMap { (index, element) in
            return [element.id: index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        return messageDict[guild]
    }
    func fastIndexChannels(_ channel: String, array: [Channel]) -> Int? {
        let messageDict = array.enumerated().compactMap { (index, element) in
            return [element.id: index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        return messageDict[channel]
    }
    func fastIndexEntries(_ entry: String, array: [ReadStateEntry]) -> Int? {
        let messageDict = array.enumerated().compactMap { (index, element) in
            return [element.id: index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        return messageDict[entry]
    }
    func order(full: GatewayD?) {
        for guild in full?.guilds ?? [] {
            guild.channels = guild.channels?.sorted(by: { $1.position ?? 0 > $0.position ?? 0 })
            let parents: [Channel] = guild.channels?.filter({ $0.type == .section }) ?? []
            let ids = Array(NSOrderedSet(array: parents)) as? [Channel] ?? []
            var ret = [Channel]()
            for id in ids {
                let matching = guild.channels?.filter { $0.parent_id == id.id }
                ret.append(id)
                ret.append(contentsOf: matching ?? [])
            }
            guild.channels = ret
        }
    }
    func assignReadStates(full: GatewayD?) {
        guard let readState = full?.read_state else { return }
        let stateDict = readState.entries.enumerated().compactMap { (index, element) in
            return [element.id: index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        for folder in Self.folders {
            for guild in folder.guilds {
                guard let channels = guild.channels else { return }
                var temp = [Channel]()
                for channel in channels {
                    guard channel.type == .normal || channel.type == .dm || channel.type == .group_dm else {
                        temp.append(channel)
                        continue
                    }
                    guard let at = stateDict[channel.id] else {
                        continue
                    }
                    channel.read_state = readState.entries[at]
                    temp.append(channel)
                }
                guild.channels = temp
            }
        }
    }
    func assignPrivateReadStates() {
        let messageDict = Self.readStates.enumerated().compactMap { (index, element) in
            return [element.id: index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        print(messageDict)
        for channel in Self.privateChannels {
            if let index = messageDict[channel.id] {
                print("Assigned to private channel")
                channel.read_state = Self.readStates[index]
            }
        }
        Self.readStates.removeAll()
    }
}

//
//  ServerListView+Misc.swift
//  ServerListView+Misc
//
//  Created by evelyn on 2021-09-12.
//

import Foundation

extension ServerListView {
    func fastIndexGuild(_ guild: String, array: [Guild]) -> Int? {
        let messageDict = array.enumerated().compactMap { (index, element) in
            return [element.id:index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        return messageDict[guild]
    }
    func fastIndexChannels(_ channel: String, array: [Channel]) -> Int? {
        let messageDict = array.enumerated().compactMap { (index, element) in
            return [element.id:index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        return messageDict[channel]
    }
    func fastIndexEntries(_ entry: String, array: [ReadStateEntry]) -> Int? {
        let messageDict = array.enumerated().compactMap { (index, element) in
            return [element.id:index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        return messageDict[entry]
    }
    func order() {
        for guild in full?.guilds ?? [] {
            guild.channels = guild.channels?.sorted(by: { $1.position ?? 0 > $0.position ?? 0 })
            let parents: [Channel] = guild.channels?.filter( { $0.type == .section } ) ?? []
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
    func assignReadStates() {
        guard let readState = full?.read_state else { return }
        for guild in guilds {
            for channel in guild.channels ?? [] {
                if let index = fastIndexEntries(channel.id, array: readState.entries), channel.type != .section || channel.type != .stage || channel.type != .voice  {
                    channel.guild_id = guild.id
                    channel.read_state = readState.entries[index]
                }
            }
        }
        
        for channel in privateChannels {
            if channel.type != .section || channel.type != .stage || channel.type != .voice  {
                if let index = fastIndexEntries(channel.id, array: readState.entries) {
                    channel.read_state = readState.entries[index]
                }
            }
        }
    }
}

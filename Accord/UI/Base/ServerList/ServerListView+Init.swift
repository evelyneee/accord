//
//  ServerListView+Init.swift
//  Accord
//
//  Created by evelyn on 2022-02-14.
//

import Foundation
import SwiftUI

extension ServerListView {
    // This is very messy but it allows the rest of the code to be cleaner. Sorry not sorry!
    @_optimize(speed)
    init(_ readyPacket: GatewayD) {
                
        let appModel = AppGlobals()
        
        let previousServer = UserDefaults.standard.object(forKey: "SelectedServer") as? String
        
        // Set status for the indicator
        status = readyPacket.user_settings?.status

        // If there are no folders there's nothing to do
        guard appModel.folders.isEmpty else {
            return
        }
        
        Storage.mergedMembers = readyPacket.merged_members
            .compactMap(\.first)
            .enumerated()
            .map { [readyPacket.guilds[$0].id: $1] }
            .flatMap { $0 }
            .reduce([String: Guild.MergedMember]()) { dict, tuple in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            }
        
        let relationshipKeys = readyPacket.relationships.generateKeyMap()
        
        readyPacket.users.forEach {
            if let idx = relationshipKeys[$0.id] {
                $0.relationship = readyPacket.relationships[idx]
            }
        }
        
        Storage.users = readyPacket.users
            .flatMap { [$0.id: $0] }
            .reduce([String: User]()) { dict, tuple in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            }
        
        let keys = Storage.users.values.generateKeyMap()

        appModel.privateChannels = readyPacket.private_channels.map { c -> Channel in
            var c = c
            if c.recipients?.isEmpty != false {
                c.recipients = c.recipient_ids?
                    .compactMap { Array(Storage.users.values)[keyed: $0, keys] }
            }
            return c
        }
        .sorted {
            guard let firstStr = $0.last_message_id, let first = Int64(firstStr),
                  let secondStr = $1.last_message_id, let second = Int64(secondStr) else { return false }
            return first > second
        }
        
        let privateReadStateDict = readyPacket.read_state?.entries.generateKeyMap()
        appModel.privateChannels.enumerated().forEach {
            appModel.privateChannels[$0].read_state = readyPacket.read_state?.entries[keyed: $1.id, privateReadStateDict]
        }
        
        print("Binded to private channels")
        
        // Bind the merged member objects to the guilds
        readyPacket.guilds = readyPacket.guilds.enumerated()
            .map { index, guild -> Guild in
                var guild = guild
                guild.mergedMember = readyPacket.merged_members[index].first

                if let role = guild.roles?.filter({ $0.id == guild.mergedMember?.hoisted_role }).first {
                    guild.guildPermissions = role.permissions
                }
                return guild
            }
        
        statusText = readyPacket.user_settings?.custom_status?.text
        
        // Order the channels
        readyPacket.assignReadStates(appModel)
        readyPacket.order()
        var guildOrder = readyPacket.user_settings?.guild_positions ?? []
        var folderTemp = readyPacket.user_settings?.guild_folders ?? []
        
        // Create a folder for every guild outside folders
        let folderGuildIDsList = readyPacket.user_settings?.guild_folders.map(\.guild_ids).joined() ?? [[]].joined()
        readyPacket.guilds.forEach { guild in
            if !guildOrder.contains(guild.id) {
                guildOrder.insert(guild.id, at: 0)
            }
            if !folderGuildIDsList.contains(guild.id) {
                folderTemp.insert(.init(guild_ids: [guild.id]), at: 0)
            }
        }

        // Form the folders and fix the guild objects
        let guildKeyMap = readyPacket.guilds.generateKeyMap()
        let guildTemp = guildOrder.compactMap { readyPacket.guilds[keyed: $0, guildKeyMap] }

        if let previousServer = previousServer, previousServer != "@me" {
            print("setting")
            self.viewModel = ServerListViewModel(guild: guildTemp[keyed: previousServer], readyPacket: readyPacket)
            self.selectedServer = previousServer
        } else {
            self.viewModel = ServerListViewModel(guild: nil, readyPacket: readyPacket)
            self.viewModel.upcomingGuild = nil
            self.selectedServer = "@me"
        }
        
        // format folders
        let guildDict = guildTemp.generateKeyMap()
        let folders = folderTemp
            .map { folder -> GuildFolder in
                folder.guilds = folder.guild_ids
                    .compactMap { guildDict[$0] }
                    .map { id -> Guild in
                        var guild = guildTemp[id]
                        guild.emojis.removeAll()
                        guild.channels = guild.channels
                            .compactMap { channel -> Channel in
                                var channel = channel
                                channel.guild_id = guild.id
                                channel.guild_icon = guild.icon
                                channel.guild_name = guild.name ?? "Unknown Guild"
                                return channel
                            }
                        return guild
                    }
                    .makeContiguousArray()
                return folder
            }
            .filter { !$0.guilds.isEmpty }

        appModel.folders = ContiguousArray(folders)
        
        MediaRemoteWrapper.status = readyPacket.user_settings?.status
        Activity.current = Activity (
            emoji: StatusEmoji(
                name: readyPacket.user_settings?.custom_status?.emoji_name ?? Array(Storage.emotes.values.joined())[keyed: readyPacket.user_settings?.custom_status?.emoji_id ?? ""]?.name,
                id: readyPacket.user_settings?.custom_status?.emoji_id,
                animated: false
            ),
            name: "Custom Status",
            type: 4,
            state: readyPacket.user_settings?.custom_status?.text
        )
        wss?.presences.append(Activity.current!)

        self.appModel = appModel
        Storage.globals = appModel
    }
}

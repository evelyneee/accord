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
    init(_ readyPacket: GatewayD) {
        let previousServer = UserDefaults.standard.object(forKey: "SelectedServer") as? String

        // Set status for the indicator
        status = readyPacket.user_settings?.status

        // If there are no folders there's nothing to do
        guard Storage.folders.isEmpty else {
            return
        }

        let keys = readyPacket.users.generateKeyMap()
        Storage.privateChannels = readyPacket.private_channels.map { c -> Channel in
            var c = c
            if c.recipients?.isEmpty != false {
                c.recipients = c.recipient_ids?
                    .compactMap { readyPacket.users[keyed: $0, keys] }
            }
            return c
        }
        .sorted { $0.last_message_id ?? "" > $1.last_message_id ?? "" }

        assignPrivateReadStates(readyPacket.read_state?.entries ?? [])

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

        // Set presence
        MediaRemoteWrapper.status = readyPacket.user_settings?.status
        Activity.current = Activity(
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
        statusText = readyPacket.user_settings?.custom_status?.text

        // Save the emotes for easy access
        Storage.emotes = readyPacket.guilds
            .map { ["\($0.id)$\($0.name ?? "Unknown Guild")": $0.emojis] }
            .flatMap { $0 }
            .reduce([String: [DiscordEmote]]()) { dict, tuple in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            }

        // Order the channels
        readyPacket.assignReadStates()
        readyPacket.order()
        var guildOrder = readyPacket.user_settings?.guild_positions ?? []
        var folderTemp = readyPacket.user_settings?.guild_folders ?? []

        // Create a folder for every guild outside folders
        readyPacket.guilds.forEach { guild in
            if !guildOrder.contains(guild.id) {
                guildOrder.insert(guild.id, at: 0)
                folderTemp.insert(GuildFolder(name: nil, color: nil, guild_ids: [guild.id]), at: 0)
            }
        }

        // Form the folders and fix the guild objects
        let guildKeyMap = readyPacket.guilds.generateKeyMap()
        let guildTemp = guildOrder
            .compactMap { readyPacket.guilds[keyed: $0, guildKeyMap] }

        // format folders
        let guildDict = guildTemp.generateKeyMap()
        let folders = folderTemp
            .map { folder -> GuildFolder in
                let folder = folder
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
                return folder
            }
            .filter { !$0.guilds.isEmpty }

        Storage.folders = folders

        DispatchQueue.global().async {
            Storage.roleColors = RoleManager.arrangeroleColors(guilds: readyPacket.guilds)
            Storage.roleNames = RoleManager.arrangeroleNames(guilds: readyPacket.guilds)
        }

        // Remote control now switched on
        MentionSender.shared.delegate = self
        if let previousServer = previousServer, previousServer != "@me" {
            print("setting")
            upcomingGuild = guildTemp[keyed: previousServer]
            selectedServer = previousServer
        } else {
            upcomingGuild = nil
            selectedServer = "@me"
        }
        upcomingSelection = UserDefaults.standard.integer(forKey: "AccordChannelIn\(upcomingGuild?.id ?? readyPacket.guilds.first?.id ?? "")")
    }
}

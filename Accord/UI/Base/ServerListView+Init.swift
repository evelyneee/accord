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
        
        // Set status for the indicator
        status = readyPacket.user_settings?.status
        
        // If there are no folders there's nothing to do
        guard Self.folders.isEmpty else {
            return
        }
        
        // Bind the merged member objects to the guilds
        readyPacket.guilds.enumerated().forEach { index, guild in
            readyPacket.guilds[index].mergedMember = readyPacket.merged_members[safe: index]?.first
            
            // Bind permissions
            if let role = readyPacket.guilds[index].roles?.filter( { $0.id == readyPacket.merged_members[safe: index]?.first?.hoisted_role } ).first {
                readyPacket.guilds[index].guildPermissions = role.permissions
            }
        }
        
        // Set presence
        MediaRemoteWrapper.status = readyPacket.user_settings?.status
        Activity.current = Activity(
            emoji: StatusEmoji(
                name: readyPacket.user_settings?.custom_status?.emoji_name ?? "",
                id: readyPacket.user_settings?.custom_status?.emoji_id ?? "",
                animated: false
            ),
            name: "Custom Status",
            type: 4
        )
        
        // Save the emotes for easy access
        Emotes.emotes = readyPacket.guilds
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
        let guildTemp = guildOrder.compactMap { guildKeyMap[$0] }.compactMap { readyPacket.guilds[$0] }
        let guildDict = guildTemp.generateKeyMap()
        for folder in folderTemp {
            for id in folder.guild_ids.compactMap({ guildDict[$0] }) {
                var guild = guildTemp[id]
                guild.emojis.removeAll()
                guild.index = id
                for channel in 0 ..< (guild.channels?.count ?? 0) {
                    guild.channels?[channel].guild_id = guild.id
                    guild.channels?[channel].guild_icon = guild.icon
                    guild.channels?[channel].guild_name = guild.name ?? "Unknown Guild"
                }
                folder.guilds.append(guild)
            }
        }
        
        // Remove empty folders
        Self.folders = folderTemp
            .filter { !$0.guilds.isEmpty }
        
        // Put the read states for access for the private channels
        Self.readStates = readyPacket.read_state?.entries ?? []
        
        // Guild selection
        selection = UserDefaults.standard.integer(forKey: "AccordChannelIn\(readyPacket.guilds.first?.id ?? "")")
        concurrentQueue.async {
            roleColors = RoleManager.arrangeRoleColors(guilds: readyPacket.guilds)
        }
        
        // Remote control now switched on
        MentionSender.shared.delegate = self
    }
}

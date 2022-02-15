//
//  ServerListView+Init.swift
//  Accord
//
//  Created by evelyn on 2022-02-14.
//

import Foundation
import SwiftUI

extension ServerListView {
    init(full: GatewayD?) {
        var full = full
        status = full?.user_settings?.status
        guard Self.folders.isEmpty else {
            return
        }
        MediaRemoteWrapper.status = full?.user_settings?.status
        Activity.current = Activity(
            emoji: StatusEmoji(
                name: full?.user_settings?.custom_status?.emoji_name ?? "",
                id: full?.user_settings?.custom_status?.emoji_id ?? "",
                animated: false
            ),
            name: "Custom Status",
            type: 4
        )
        Emotes.emotes = full?.guilds
            .map { ["\($0.id)$\($0.name ?? "Unknown Guild")": $0.emojis] }
            .flatMap { $0 }
            .reduce([String: [DiscordEmote]]()) { dict, tuple in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            } ?? [:]
        order(full: &full)
        var guildOrder = full?.user_settings?.guild_positions ?? []
        var folderTemp = full?.user_settings?.guild_folders ?? []
        full?.guilds.forEach { guild in
            if !guildOrder.contains(guild.id) {
                guildOrder.insert(guild.id, at: 0)
                folderTemp.insert(GuildFolder(name: nil, color: nil, guild_ids: [guild.id]), at: 0)
            }
        }
        let messageDict = full?.guilds.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        } ?? [:]
        let guildTemp = guildOrder.compactMap { messageDict[$0] }.compactMap { full?.guilds[$0] }
        let guildDict = guildTemp.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        }
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
        Self.folders = folderTemp
            .filter { !$0.guilds.isEmpty }
        assignReadStates(full: &full)
        Self.readStates = full?.read_state?.entries ?? []
        selection = UserDefaults.standard.integer(forKey: "AccordChannelIn\(full?.guilds.first?.id ?? "")")
        concurrentQueue.async {
            guard let guilds = full?.guilds else { return }
            roleColors = RoleManager.arrangeRoleColors(guilds: guilds)
        }
        MentionSender.shared.delegate = self
    }

}

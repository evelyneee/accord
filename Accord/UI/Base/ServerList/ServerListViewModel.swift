//
//  ServerListViewModel.swift
//  Accord
//
//  Created by evelyn on 2022-07-14.
//

import Foundation
import Combine

final class ServerListViewModel: ObservableObject {
    init (guild: Guild?, readyPacket: GatewayD?) {
        if let readyPacket {
            self.upcomingGuild = guild
            self.upcomingSelection = UserDefaults.standard.integer(forKey: "AccordChannelIn\(guild?.id ?? "")")
            DispatchQueue.global().async {
                self.setEmotes(readyPacket)
                let colors = RoleManager.arrangeroleColors(guilds: readyPacket.guilds)
                let names = RoleManager.arrangeroleNames(guilds: readyPacket.guilds)
                DispatchQueue.main.async {
                    Storage.roleColors = colors
                    Storage.roleNames = names
                }
            }
        }
    }
    
    var bag = Set<AnyCancellable>()
    
    var upcomingGuild: Guild? = nil
    var upcomingSelection: Int?
    
    func setEmotes(_ readyPacket: GatewayD) {
        // Save the emotes for easy access
        Storage.emotes = readyPacket.guilds
            .map { ["\($0.id)$\($0.name ?? "Unknown Guild")": $0.emojis] }
            .flatMap { $0 }
            .reduce([String: [DiscordEmote]]()) { dict, tuple in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            }
            .filter { !$1.isEmpty }
    }
}






















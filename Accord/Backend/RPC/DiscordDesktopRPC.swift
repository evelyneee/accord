//
//  DiscordDesktopRPC.swift
//  Accord
//
//  Created by evelyn on 2022-01-06.
//

import Foundation

final class DiscordDesktopRPC {
    class func update(guildName: String? = nil, channelName: String) {
        guard DiscordDesktopRPCEnabled else { return }
        try? wss.updatePresence(status: MediaRemoteWrapper.status ?? "dnd", since: Int(Date().timeIntervalSince1970) * 1000) {
            Activity.current!
            Activity(
                applicationID: discordDesktopRPCAppID,
                flags: 1,
                name: "Discord Desktop",
                type: 0,
                timestamp: Int(Date().timeIntervalSince1970) * 1000,
                state: guildName != nil ? "In \(guildName!)" : "Direct Messages",
                details: guildName != nil ? "Reading #\(channelName)" : "Speaking with \(channelName)"
            )
        }
    }
}

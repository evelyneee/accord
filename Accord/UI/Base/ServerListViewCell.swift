//
//  ServerListViewCell.swift
//  Accord
//
//  Created by evelyn on 2022-04-17.
//

import Foundation
import SwiftUI

struct ServerListViewCell: View {
    var channel: Channel
    @StateObject var updater: ServerListView.UpdateView
    var guildID: String { channel.guild_id ?? "@me" }
    @State var status: String? = nil
    
    private var dmLabelView: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Attachment(pfpURL(
                    channel.recipients?.first?.id,
                    channel.recipients?.first?.avatar,
                    discriminator: channel.recipients?.first?.discriminator ?? "0005"
                ))
                    .equatable()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                statusDot
                    .onAppear {
                        if let user = channel.recipients?.first {
                            wss.listenForPresence(userID: user.id) { presence in
                                self.status = presence.status
                            }
                        }
                    }
                    .onDisappear {
                        if let user = channel.recipients?.first, channel.type == .dm {
                            wss.unregisterPresence(userID: user.id)
                        }
                    }
            }
            Text(channel.computedName)
        }
    }
    
    @ViewBuilder
    private var labelView: some View {
        switch channel.type {
        case .normal:
            HStack {
                Image(systemName: "number")
                Text(channel.computedName)
            }
        case .voice:
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                Text(channel.computedName)
            }
        case .guild_news:
            HStack {
                Image(systemName: "megaphone.fill")
                Text(channel.computedName)
            }
        case .stage:
            HStack {
                Image(systemName: "person.wave.2.fill")
                Text(channel.computedName)
            }
        case .dm:
            dmLabelView
        case .group_dm:
            HStack {
                Attachment(cdnURL + "/channel-icons/\(channel.id)/\(channel.icon ?? "").png?size=24").equatable()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                Text(channel.computedName)
            }
        case .guild_public_thread:
            HStack {
                Image(systemName: "tray.full")
                Text(channel.computedName)
            }
        case .guild_private_thread:
            HStack {
                Image(systemName: "tray.full")
                Text(channel.computedName)
            }
        default:
            HStack {
                Image(systemName: "number")
                Text(channel.computedName)
            }
        }
    }
    
    private var statusDot: some View {
        Circle()
            .foregroundColor({ () -> Color in
                switch self.status {
                case "online":
                    return Color.green
                case "idle":
                    return Color.orange
                case "dnd":
                    return Color.red
                case "offline":
                    return Color.gray
                default:
                    return Color.clear
                }
            }())
            .frame(width: 7, height: 7)
    }
    
    private var readStateDot: some View {
        ZStack {
            Circle()
                .foregroundColor(Color.red)
                .frame(width: 15, height: 15)
            Text(String(channel.read_state?.mention_count ?? 0))
                .foregroundColor(Color.white)
                .fontWeight(.semibold)
                .font(.caption)
        }
    }
    
    var body: some View {
        HStack {
            labelView
            Spacer()
            if let readState = channel.read_state, readState.mention_count != 0 {
                readStateDot
            }
        }
    }
}

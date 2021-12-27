//
//  GuildView.swift
//  Accord
//
//  Created by evelyn on 2021-11-14.
//

import Foundation
import SwiftUI

struct GuildView: View {

    weak var guild: Guild?
    @Binding var selection: Int?
    var body: some View {
        List {
            HStack {
                if let level = guild?.premium_tier, level != 0 {
                    switch level {
                    case 1:
                        Image("level1").resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    case 2:
                        Image("level2").resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    case 3:
                        Image("level3").resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    default:
                        EmptyView()
                    }
                }
                Text(guild?.name ?? "Unknown guild")
                    .fontWeight(.medium)
            }
            if let id = guild?.id, let banner = guild?.banner {
                Attachment("https://cdn.discordapp.com/banners/\(id)/\(banner).png")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(10)
            }
            ForEach(guild?.channels ?? [], id: \.id) { channel in
                if channel.type == .section {
                    Text(channel.name ?? "")
                        .foregroundColor(Color.secondary)
                        .font(.subheadline)
                } else {
                    NavigationLink(destination: NavigationLazyView(ChannelView(channel, guild?.name).equatable()), tag: (Int(channel.id) ?? 0), selection: self.$selection) {
                        ServerListViewCell(channel: channel)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct ServerListViewCell: View {
    weak var channel: Channel?
    var guildID: String
    init(channel: Channel) {
        self.channel = channel
        self.guildID = channel.guild_id ?? "@me"
    }
    var body: some View {

        var readStateDot: some View {
            return ZStack {
                Circle()
                    .foregroundColor(Color.red)
                    .frame(width: 15, height: 15)
                Text(String(channel?.read_state?.mention_count ?? 0))
                    .foregroundColor(Color.white)
                    .fontWeight(.semibold)
                    .font(.caption)
            }
        }

        var windowButton: some View {
            return Button(action: {
                if let channel = channel {
                    showWindow(channel)
                }
            }) {
                Image(systemName: "arrow.up.right.circle")
            }
        }

        return HStack {
            switch channel?.type {
            case .normal:
                Label(channel?.name ?? channel?.recipients?[0].username ?? "Unknown Channel", systemImage: "number")
            case .voice:
                Label(channel?.name ?? channel?.recipients?[0].username ?? "Unknown Channel", systemImage: "speaker.wave.2.fill")
            case .guild_news:
                Label(channel?.name ?? channel?.recipients?[0].username ?? "Unknown Channel", systemImage: "megaphone.fill")
            case .stage:
                Label(channel?.name ?? channel?.recipients?[0].username ?? "Unknown Channel", systemImage: "person.2.fill")
            case .dm:
                HStack {
                    Attachment(pfpURL(channel?.recipients?[0].id, channel?.recipients?[0].avatar).appending("?size=48")).equatable()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    Text(channel?.name ?? channel?.recipients?[0].username ?? "Unknown Channel")
                }
            case .group_dm:
                HStack {
                    Attachment("https://cdn.discordapp.com/channel-icons/\(channel?.id ?? "")/\(channel?.icon ?? "").png?size=48").equatable()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    Text(channel?.name ?? channel?.recipients?[0].username ?? "Unknown Channel")
                }
            default:
                Label(channel?.name ?? channel?.recipients?[0].username ?? "Unknown Channel", systemImage: "camera.metering.unknown")
            }
            Spacer()
            if let readState = channel?.read_state, readState.mention_count != 0 {
                readStateDot
            }
            windowButton
        }
    }
}

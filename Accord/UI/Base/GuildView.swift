//
//  GuildView.swift
//  Accord
//
//  Created by evelyn on 2021-11-14.
//

import Foundation
import SwiftUI

struct GuildView: View {
    
    @Binding var guild: Guild
    @Binding var selection: Int?
    var body: some View {
        return List {
            VStack {
                HStack {
                    if let level = guild.premium_tier, level != 0 {
                        Text(String(describing: level))
                    }
                    Text(guild.name)
                        .fontWeight(.medium)
                }
            }
            if let banner = guild.banner {
                Attachment("https://cdn.discordapp.com/banners/\(guild.id)/\(banner).png")
                    .cornerRadius(10)
            }
            ForEach(guild.channels ?? [], id: \.id) { channel in
                if channel.type == .section {
                    Text(channel.name ?? "")
                        .foregroundColor(Color.secondary)
                        .font(.subheadline)
                } else {
                    NavigationLink(destination: NavigationLazyView(ChannelView(channel).equatable()), tag: (Int(channel.id) ?? 0), selection: self.$selection) {
                        ServerListViewCell(channel: channel).equatable()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct ServerListViewCell: View, Equatable {
    var channel: Channel
    var guildID: String
    init(channel: Channel) {
        self.channel = channel
        self.guildID = channel.guild_id ?? "@me"
    }
    var body: some View {
        var label: some View {
            return Group {
                switch channel.type {
                case .normal:
                    Label(channel.name ?? channel.recipients?[0].username ?? "Unknown Channel", systemImage: "number")
                case .voice:
                    Label(channel.name ?? channel.recipients?[0].username ?? "Unknown Channel", systemImage: "speaker.wave.2.fill")
                case .guild_news:
                    Label(channel.name ?? channel.recipients?[0].username ?? "Unknown Channel", systemImage: "megaphone.fill")
                case .stage:
                    Label(channel.name ?? channel.recipients?[0].username ?? "Unknown Channel", systemImage: "person.2.fill")
                case .dm:
                    HStack {
                        Attachment(pfpURL(channel.recipients?[0].id, channel.recipients?[0].avatar).appending("?size=80"), size: CGSize(width: 80, height: 80))
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                        Text(channel.name ?? channel.recipients?[0].username ?? "Unknown Channel")
                    }
                case .group_dm:
                    HStack {
                        Attachment("https://cdn.discordapp.com/channel-icons/\(channel.id)/\(channel.icon ?? "").png?size=64", size: CGSize(width: 64, height: 64))
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                        Text(channel.name ?? channel.recipients?[0].username ?? "Unknown Channel")
                    }
                default:
                    Label(channel.name ?? channel.recipients?[0].username ?? "Unknown Channel", systemImage: "camera.metering.unknown")
                }
            }
        }
        
        var readStateDot: some View {
            return ZStack {
                Circle()
                    .foregroundColor(Color.red)
                    .frame(width: 15, height: 15)
                Text(String(channel.read_state?.mention_count ?? 0))
                    .foregroundColor(Color.white)
                    .fontWeight(.semibold)
                    .font(.caption)
            }
        }
        
        var windowButton: some View {
            return Button(action: { [weak channel] in
                if let channel = channel {
                    showWindow(channel)
                }
            }) {
                Image(systemName: "arrow.up.right.circle")
            }
        }
        
        return HStack {
            label
            Spacer()
            if let readState = channel.read_state, readState.mention_count != 0 {
                readStateDot
            }
            windowButton
        }
    }
}


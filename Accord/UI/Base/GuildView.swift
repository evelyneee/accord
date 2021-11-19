//
//  GuildView.swift
//  Accord
//
//  Created by evelyn on 2021-11-14.
//

import Foundation
import SwiftUI

struct GuildView: View, Equatable {
    static func == (lhs: GuildView, rhs: GuildView) -> Bool {
        return lhs.guild.id == rhs.guild.id
    }
    
    @Binding var guild: Guild
    @State var selection: Int?
    var body: some View {
        lazy var banner: Optional<Attachment> = {
            guard let banner = guild.banner else { return nil }
            let url = "https://cdn.discordapp.com/banners/\(guild.id)/\(banner).png"
            return Attachment(url)
        }()
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
            banner
            ForEach(guild.channels ?? [], id: \.id) { channel in
                if channel.type == .section {
                    Text(channel.name ?? "")
                        .foregroundColor(Color.secondary)
                        .font(.subheadline)
                } else {
                    NavigationLink(destination: NavigationLazyView(ChannelView(guildID: guild.id, channelID: channel.id, channelName: channel.name ?? "").equatable()), tag: (Int(channel.id) ?? 0), selection: self.$selection) {
                        ServerListViewCell(channel: channel, guildID: guild.id).equatable()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 5)
        }

    }
}

struct ServerListViewCell: View, Equatable {
    
    var channel: Channel
    var guildID: String
    init(channel: Channel, guildID: String = "@me") {
        self.channel = channel
        self.guildID = guildID
    }
    var body: some View {
        
        lazy var label: some View = {
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
        }()
        
        lazy var readStateDot: some View = {
            return ZStack {
                Circle()
                    .foregroundColor(Color.red)
                    .frame(width: 15, height: 15)
                Text(String(channel.read_state?.mention_count ?? 0))
                    .foregroundColor(Color.white)
                    .fontWeight(.semibold)
                    .font(.caption)
            }
        }()
        
        lazy var windowButton: some View = {
            return Button(action: { [weak channel] in
                showWindow(guildID: guildID, channelID: channel?.id ?? "", channelName: channel?.name ?? "")
            }) {
                Image(systemName: "arrow.up.right.circle")
            }
        }()
        
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


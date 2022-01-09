//
//  GuildView.swift
//  Accord
//
//  Created by evelyn on 2021-11-14.
//

import Foundation
import SwiftUI

struct GuildView: View {

    var guild: Guild
    @Binding var selection: Int?
    var body: some View {
        List {
            HStack {
                if let level = guild.premium_tier, level != 0 {
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
                Text(guild.name)
                    .fontWeight(.medium)
            }
            if let banner = guild.banner {
                Attachment("https://cdn.discordapp.com/banners/\(guild.id)/\(banner).png")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(10)
            }
            ForEach(guild.channels ?? [], id: \.id) { channel in
                if channel.type == .section {
                    Text(channel.name ?? "Unknown channel")
                        .foregroundColor(Color.secondary)
                        .font(.subheadline)
                } else {
                    NavigationLink(destination: NavigationLazyView(ChannelView(channel, guild.name).equatable()), tag: (Int(channel.id) ?? 0), selection: self.$selection) {
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
    @State var hovered: Bool = false
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

        return HStack {
            switch channel?.type {
            case .normal:
                HStack {
                    Image(systemName: "number")
                    Text(channel?.computedName ?? "Unknown Channel")
                }
            case .voice:
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text(channel?.computedName ?? "Unknown Channel")
                }
            case .guild_news:
                HStack {
                    Image(systemName: "megaphone.fill")
                    Text(channel?.computedName ?? "Unknown Channel")
                }
            case .stage:
                HStack {
                    Image(systemName: "person.2.fill")
                    Text(channel?.computedName ?? "Unknown Channel")
                }
            case .dm:
                HStack {
                    Attachment(pfpURL(channel?.recipients?[0].id, channel?.recipients?[0].avatar)).equatable()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    Text(channel?.computedName ?? "Unknown Channel")
                }
            case .group_dm:
                HStack {
                    Attachment("https://cdn.discordapp.com/channel-icons/\(channel?.id ?? "")/\(channel?.icon ?? "").png?size=24").equatable()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    Text(channel?.computedName ?? "Unknown Channel")
                }
            default:
                HStack {
                    Image(systemName: "number")
                    Text(channel?.computedName ?? "Unknown Channel")
                }
            }
            Spacer()
            if let readState = channel?.read_state, readState.mention_count != 0 {
                readStateDot
            }
            if hovered {
                Button(action: {
                    if let channel = channel {
                        showWindow(channel)
                    }
                }) {
                    Image(systemName: "arrow.up.right.circle")
                }
            }
        }.onHover { val in
            self.hovered = val
        }
    }
}

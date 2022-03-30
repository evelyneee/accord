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
    @StateObject var updater: ServerListView.UpdateView
    var body: some View {
        List {
            HStack {
                if let level = guild.premium_tier, level != 0 {
                    switch level {
                    case 1:
                        Image(systemName: "star").resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                    case 2:
                        Image(systemName: "star.leadinghalf.filled").resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                    case 3:
                        Image(systemName: "star.fill").resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                    default:
                        EmptyView()
                    }
                }
                Text(guild.name ?? "Unknown Guild")
                    .fontWeight(.medium)
            }
            if let banner = guild.banner {
                Attachment(cdnURL + "/banners/\(guild.id)/\(banner).png")
                    .equatable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(10)
                    .animation(nil, value: UUID())
            }
            ForEach(guild.channels ?? .init(), id: \.id) { channel in
                if channel.type == .section {
                    Text(channel.name ?? "Unknown channel")
                        .foregroundColor(Color.secondary)
                        .font(.subheadline)
                } else {
                    NavigationLink(destination: NavigationLazyView(ChannelView(channel, guild.name).equatable()), tag: Int(channel.id) ?? 0, selection: self.$selection) {
                        ServerListViewCell(channel: channel, updater: self.updater)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .foregroundColor(channel.read_state?.last_message_id == channel.last_message_id ? Color.secondary : nil)
                    .opacity(channel.read_state?.last_message_id != channel.last_message_id ? 1 : 0.5)
                    .padding((channel.type == .guild_public_thread || channel.type == .guild_private_thread) ? .leading : [])
                    .onChange(of: self.selection, perform: { _ in
                        if self.selection == Int(channel.id) {
                            channel.read_state?.mention_count = 0
                            channel.read_state?.last_message_id = channel.last_message_id
                        }
                    })
                    .contextMenu {
                        Button("Copy Channel ID") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(channel.id, forType: .string)
                        }
                        Button(action: {
                            channel.read_state?.mention_count = 0
                            channel.read_state?.last_message_id = channel.last_message_id
                        }) {
                            Text("Mark as read")
                        }
                        Button(action: {
                            showWindow(channel)
                        }) {
                            Text("Open in new window")
                        }
                    }
                    .animation(nil, value: UUID())
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct ServerListViewCell: View {
    var channel: Channel
    @StateObject var updater: ServerListView.UpdateView
    var guildID: String { self.channel.guild_id ?? "@me" }
    var body: some View {
        var readStateDot: some View {
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

        return HStack {
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
                HStack {
                    Attachment(pfpURL(channel.recipients?[0].id, channel.recipients?[0].avatar, discriminator: channel.recipients?[0].discriminator ?? "0005")).equatable()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    Text(channel.computedName)
                }
            case .group_dm:
                HStack {
                    Attachment(cdnURL + "/channel-icons/\(channel.id )/\(channel.icon ?? "").png?size=24").equatable()
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
            Spacer()
            if let readState = channel.read_state, readState.mention_count != 0 {
                readStateDot
            }
        }
    }
}

struct GuildListPreview: View {
    @State var guild: Guild
    @Binding var selectedServer: Int?
    @StateObject var updater: ServerListView.UpdateView
    var body: some View {
        if let icon = guild.icon {
            Attachment(iconURL(guild.id, icon))
                .equatable()
                .frame(width: 45, height: 45)
                .cornerRadius(selectedServer == guild.index ? 15.0 : 23.5)
        } else {
            if let name = guild.name {
                Text(name)
                    .equatable()
                    .frame(width: 45, height: 45)
                    .background(Color.secondary)
                    .cornerRadius(selectedServer == guild.index ? 15.0 : 23.5)
            } else {
                Image(systemName: "questionmark")
                    .equatable()
                    .frame(width: 45, height: 45)
                    .background(Color.secondary)
                    .cornerRadius(selectedServer == guild.index ? 15.0 : 23.5)
            }
        }
    }
}

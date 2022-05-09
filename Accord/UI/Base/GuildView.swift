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
                    .fontWeight(.semibold)
                    .font(.system(size: 13))
            }
            if let banner = guild.banner {
                Attachment(cdnURL + "/banners/\(guild.id)/\(banner).png", size: nil)
                    .equatable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(10)
                    .animation(nil, value: UUID())
            }
            ForEach(guild.channels ?? .init(), id: \.id) { channel in
                if channel.type == .section {
                    Text(channel.name?.uppercased() ?? "")
                        .fontWeight(.bold)
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 10))
                } else {
                    NavigationLink(
                        destination: NavigationLazyView(ChannelView(channel, guild.name).equatable()),
                        tag: Int(channel.id) ?? 0,
                        selection: self.$selection
                    ) {
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

struct GuildListPreview: View {
    @State var guild: Guild
    @Binding var selectedServer: Int?
    @StateObject var updater: ServerListView.UpdateView
    var body: some View {
        if let icon = guild.icon {
            Attachment(iconURL(guild.id, icon))
                .equatable()
                .modifier(GuildHoverAnimation(hasIcon: true, selected: selectedServer == guild.index))
        } else {
            if let name = guild.name {
                Text(name.components(separatedBy: " ").compactMap({ $0.first }).map(String.init).joined())
                    .equatable()
                    .modifier(GuildHoverAnimation(hasIcon: false, selected: selectedServer == guild.index))
            } else {
                Image(systemName: "questionmark")
                    .equatable()
                    .modifier(GuildHoverAnimation(hasIcon: false, selected: selectedServer == guild.index))
            }
        }
    }
}

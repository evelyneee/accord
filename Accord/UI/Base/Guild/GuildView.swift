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
    @State var invitePopup: Bool = false
    var body: some View {
        List {
            Menu(content: {
                Button("Generate new invite") {
                    self.invitePopup.toggle()
                }
                Button("Copy ID") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(guild.id, forType: .string)
                }
                Divider()
                if guild.owner_id != user_id {
                    Button("Leave Server") {
                        DispatchQueue.global().async {
                            let url = URL(string: rootURL)?
                                .appendingPathComponent("users")
                                .appendingPathComponent("@me")
                                .appendingPathComponent("guilds")
                                .appendingPathComponent(guild.id)
                            Request.ping(url: url, headers: Headers.init(
                                userAgent: discordUserAgent,
                                token: AccordCoreVars.token,
                                bodyObject: ["lurking":false],
                                type: .DELETE,
                                discordHeaders: true
                            ))
                        }
                    }
                }
            }, label: {
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
            })
            .menuStyle(BorderlessButtonMenuStyle())
            .sheet(isPresented: self.$invitePopup, content: {
                NewInviteSheet(selection: self.$selection, isPresented: self.$invitePopup)
                    .frame(width: 350, height: 250)
            })
            if let banner = guild.banner {
                if banner.prefix(2) == "a_" {
//                    GifView(cdnURL + "/banners/\(guild.id)/\(banner).gif?size=512")
//                        .drawingGroup()
//                        .cornerRadius(3)
//                        .animation(nil, value: UUID())
//                        .edgesIgnoringSafeArea(.all)
//                        .padding(.vertical, 5)
                } else {
                    Attachment(cdnURL + "/banners/\(guild.id)/\(banner).png?size=512", size: nil)
                        .equatable()
                        .cornerRadius(3)
                        .animation(nil, value: UUID())
                        .edgesIgnoringSafeArea(.all)
                        .padding(.vertical, 5)
                }
            }
            ForEach(guild.channels, id: \.id) { channel in
                if channel.type == .section {
                    Text(channel.name?.uppercased() ?? "")
                        .fontWeight(.bold)
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 10))
                } else {
                    NavigationLink(
                        tag: Int(channel.id) ?? 0,
                        selection: self.$selection,
                        destination: {
                            NavigationLazyView (
                                ChannelView(channel, guild.name)
                                    .equatable()
                                    .onAppear {
                                        let prevCount = channel.read_state?.mention_count
                                        channel.read_state?.mention_count = 0
                                        channel.read_state?.last_message_id = channel.last_message_id
                                        if prevCount != 0 { self.updater.updateView() }
                                    }
                                    .onDisappear {
                                        let prevCount = channel.read_state?.mention_count
                                        channel.read_state?.mention_count = 0
                                        channel.read_state?.last_message_id = channel.last_message_id
                                        if prevCount != 0 { self.updater.updateView() }
                                    }
                            )
                        }, label: {
                            ServerListViewCell(
                                channel: channel,
                                updater: self.updater
                            )
                        }
                    )
                    .buttonStyle(BorderlessButtonStyle())
                    .foregroundColor(channel.read_state?.last_message_id == channel.last_message_id ? Color.secondary : nil)
                    .opacity(channel.read_state?.last_message_id != channel.last_message_id ? 1 : 0.5)
                    .padding((channel.type == .guild_public_thread || channel.type == .guild_private_thread) ? .leading : [])
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
    @Binding var updater: Bool
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

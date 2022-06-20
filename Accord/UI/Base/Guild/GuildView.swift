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
    
    @State var width: CGFloat?
    
    var body: some View {
        List {
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
                            if channel.type == .forum {
                                NavigationLazyView(ForumChannelList(forumChannel: channel))
                            } else {
                                NavigationLazyView(
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
                            }
                        }, label: {
                            ServerListViewCell(
                                channel: channel,
                                updater: self.updater
                            )
                        }
                    )
                    .buttonStyle(BorderlessButtonStyle())
                    .foregroundColor(channel.read_state != nil && channel.read_state?.last_message_id == channel.last_message_id ? Color.secondary : nil)
                    .opacity(channel.read_state != nil && channel.read_state?.last_message_id != channel.last_message_id ? 1 : 0.5)
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
                        Button(action: {
                            showPanel(channel)
                        }) {
                            Text("Open in new panel")
                        }
                    }
                    .animation(nil, value: UUID())
                }
            }
        }
        .listStyle(.sidebar)
        .readSize {
            self.width = $0.width
        }
        .toolbar {
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
                            Request.ping(url: url, headers: Headers(
                                userAgent: discordUserAgent,
                                token: Globals.token,
                                bodyObject: ["lurking": false],
                                type: .DELETE,
                                discordHeaders: true
                            ))
                        }
                    }
                }
            }, label: {
                HStack {
                    switch guild.premium_tier {
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
                    
                    Text(guild.name ?? "Unknown Guild")
                        .fontWeight(.semibold)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            })
            .frame(width: (self.width ?? 190) - 32, alignment: .trailing)
            .padding(.leading, 16)
            .menuStyle(BorderlessButtonMenuStyle())
            .sheet(isPresented: self.$invitePopup, content: {
                NewInviteSheet(selection: self.$selection, isPresented: self.$invitePopup)
                    .frame(width: 350, height: 250)
            })
        }
    }
}

struct GuildListPreview: View {
    @State var guild: Guild
    @Binding var selectedServer: String?
    @Binding var updater: Bool
    var body: some View {
        if let icon = guild.icon {
            Attachment(iconURL(guild.id, icon))
                .equatable()
                .modifier(GuildHoverAnimation(hasIcon: true, selected: selectedServer == guild.id))
        } else {
            if let name = guild.name {
                Text(name.components(separatedBy: " ").compactMap(\.first).map(String.init).joined())
                    .equatable()
                    .modifier(GuildHoverAnimation(hasIcon: false, selected: selectedServer == guild.id))
            } else {
                Image(systemName: "questionmark")
                    .equatable()
                    .modifier(GuildHoverAnimation(hasIcon: false, selected: selectedServer == guild.id))
            }
        }
    }
}


extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

func showPanel(_ channel: Channel) {
    let panel2 = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600), styleMask: [.titled, .nonactivatingPanel, .closable], backing: .buffered, defer: true)
    panel2.title = channel.computedName
    panel2.level = .init(Int(CGWindowLevelForKey(CGWindowLevelKey.floatingWindow)))
    panel2.contentView = NSHostingView(rootView: ChannelView(channel, channel.guild_name))
    panel2.collectionBehavior = [.fullScreenAuxiliary]
    panel2.orderFrontRegardless()
}

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
    
    @Binding var selectedChannel: Channel?
        
    @State var invitePopup: Bool = false
    
    @State var width: Double?
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    @EnvironmentObject
    var userSettings: UserGuildSettings
    
    @AppStorage("HideMutedChannels")
    var hideMutedChannels: Bool = false
    
    var body: some View {
        #warning("Add back banners")
        List(guild.channels, id: \.self, selection: $selectedChannel) { channel in
            if hideMutedChannels && (hideMutedChannels ? false : (userSettings.mutedChannels.contains(channel.id) || userSettings.mutedChannels.contains(channel.parent_id ?? channel.id))) {
            } else if channel.type == .section {
                Text(channel.name?.uppercased() ?? "")
                    .fontWeight(.bold)
                    .foregroundColor(Color.secondary)
                    .font(.system(size: 10))
            } else {
                PlatformNavigationLink(
                    item: channel,
                    selection: self.$selectedChannel,
                    destination: {
                        Group {
                            if channel.type == .forum {
                                NavigationLazyView(ForumChannelList(forumChannel: channel))
                            } else if let channel = selectedChannel {
                                NavigationLazyView(
                                    ChannelView(self.$appModel.selectedChannel, guild.name)
                                        .equatable()
                                        .onAppear {
                                            let channelID = channel.id
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [channelID] in
                                                if self.selectedChannel?.id == channelID {
                                                    channel.read_state?.mention_count = 0
                                                    channel.read_state?.last_message_id = channel.last_message_id
                                                }
                                            })
                                        }
                                        .onDisappear { [channel] in
                                            channel.read_state?.mention_count = 0
                                            channel.read_state?.last_message_id = channel.last_message_id
                                        }
                                )
                            }
                        }
                    },
                    label: {
                        ServerListViewCell(
                            channel: .constant(channel)
                        )
                    }
                )
                .buttonStyle(.borderless)
                .foregroundColor(channel.read_state != nil && channel.read_state?.last_message_id == channel.last_message_id ? Color.secondary : nil)
                .padding((channel.type == .guild_public_thread || channel.type == .guild_private_thread) ? .leading : [])
                .contextMenu {
                    Button("Copy Channel ID") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(channel.id, forType: .string)
                    }
                    Button("Mark as read") {
                        channel.read_state?.mention_count = 0
                        channel.read_state?.last_message_id = channel.last_message_id
                    }
                    Button("Open in new window") {
                        showWindow(channel, globals: self.appModel)
                    }
                    Button("Open in new panel") {
                        showPanel(channel, globals: self.appModel)
                    }
                    //#warning("TODO: Check for permissions for this")
                    Divider()
                    Button("Delete channel") {
                        let headers = Headers(
                            contentType: nil,
                            token: Globals.token,
                            type: .DELETE,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/@me",
                            empty: true
                        )
                        Request.ping(url: URL(string: rootURL + "/channels/\(channel.id)"), headers: headers)
                        if self.selectedChannel?.id == channel.id {
                            self.selectedChannel = nil
                        }
                        guard let index = guild.channels[indexOf: channel.id] else { return }
                        guild.channels.remove(at: index)
                    }
                }
                .animation(nil, value: UUID())
            }
        }
        .navigationTitle(Text("Channels"))
        //.listStyle(.sidebar)
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
                        Image(systemName: "star")
                            .font(.system(size: 15))
                    case 2:
                        Image(systemName: "star.leadinghalf.filled")
                            .font(.system(size: 15))
                    case 3:
                        Image(systemName: "star.fill")
                            .font(.system(size: 15))
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
                NewInviteSheet(selection: self.$selectedChannel, isPresented: self.$invitePopup)
                    .frame(width: 350, height: 250)
            })
        }
    }
}

struct GuildListPreview: View {
    @Binding var guild: Guild
    @Binding var selectedServer: String?
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

@MainActor func showPanel(_ channel: Channel, globals: AppGlobals) {
    let panel2 = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600), styleMask: [.titled, .nonactivatingPanel, .closable], backing: .buffered, defer: true)
    panel2.title = channel.computedName
    panel2.level = .init(Int(CGWindowLevelForKey(CGWindowLevelKey.floatingWindow)))
    panel2.contentView = NSHostingView(rootView: ChannelView(.constant(channel), channel.guild_name).environmentObject(globals))
    panel2.collectionBehavior = [.fullScreenAuxiliary]
    panel2.orderFrontRegardless()
}

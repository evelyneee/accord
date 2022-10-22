//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import Combine
import SwiftUI
import UserNotifications

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

extension Reachability {
    var connected: Bool {
        connection == .wifi || connection == .cellular
    }
}

struct GuildHoverAnimation: ViewModifier {
    var color: Color = Color.accentColor.opacity(0.5)
    var hasIcon: Bool
    var frame: Double = 45
    var selected: Bool
    @State var hovered: Bool = false

    func body(content: Content) -> some View {
        content
            .frame(width: frame, height: frame)
            .background(!hasIcon && hovered ? color : Color.clear)
            .onHover(perform: { res in
                withAnimation(Animation.easeInOut(duration: 0.1)) {
                    hovered = res
                }
            })
            .cornerRadius(hovered || selected ? 15 : frame / 2)
    }
}

func pingCount(guild: Guild) -> Int {
    guild.channels.reduce(0, { num, channel in
        num + (channel.read_state?.mention_count ?? 0)
    })
}

func unreadMessages(guild: Guild) -> Bool {
    let array = !guild.channels
        .filter {
            if let messageID = $0.read_state?.last_message_id, messageID != $0.last_message_id {
                return true // unread
            }
            return false // read / no read state
        }
        .isEmpty
    return array
}

struct ServerListView: View {
    
    @MainActor @AppStorage("SelectedServer")
    var selectedServer: String?
    
    @MainActor @ObservedObject
    public var appModel: AppGlobals = .init()
    
    @MainActor @ObservedObject
    public var discordSettings: DiscordSettings = .init()
    
    @MainActor @ObservedObject
    public var userGuildSettings: UserGuildSettings = .init()
    
    @AppStorage("DiscordColorScheme")
    var discordColorScheme: Bool = false
    
    @AppStorage("HideMutedChannels")
    var hideMutedChannels: Bool = false
    
    internal static var readStates: [ReadStateEntry] = .init()
    var statusText: String? = nil
    @State var status: String? = nil
    @State var iconHovered: Bool = false
    @State var isShowingJoinServerSheet: Bool = false
    
    @State var popup: Bool = false
    
    @ObservedObject var viewModel: ServerListViewModel = ServerListViewModel(guild: nil, readyPacket: nil)
    
    @State var width: Double?
    
    @State var invitePopup: Bool = false
    
    var onlineButton: some View {
        Button(action: {
            AccordApp.error(text: "Offline", additionalDescription: "Check your network connection")
        }, label: {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title)
        })
        .buttonStyle(.borderless)
    }
    
    var statusIndicator: some View {
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
    
    var body: some View {
        PlatformNavigationView(sidebar: {
            HStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Messages button
                    LazyVStack {
                        if reachability?.connected == false {
                            onlineButton.buttonStyle(BorderlessButtonStyle())
                            Color.gray
                                .frame(width: 30, height: 1)
                                .opacity(0.75)
                        }
                        DMButton(
                            selectedServer: self.$selectedServer,
                            selectedGuild: self.$appModel.selectedGuild
                        )
                        .fixedSize()
                        Color.gray
                            .frame(width: 30, height: 1)
                            .opacity(0.75)
                        FolderListView(selectedServer: self.$selectedServer, selectedGuild: self.$appModel.selectedGuild)
                            .padding(.trailing, 3.5)
                        Color.gray
                            .frame(width: 30, height: 1)
                            .opacity(0.75)
                        JoinServerButton()
                    }
                }
                .frame(width: 80)
                .padding(.top, 5)
                Divider()
                
                // MARK: - Loading UI
                
                Group {
                    if selectedServer == "@me" {
                        PrivateChannelsView()
                            .animation(nil, value: UUID())
                    } else if let guild = self.appModel.selectedGuild {
                        guildView(guild)
                    }
                }
                .frame(minWidth: 240)
            }
        }, detail: { [weak appModel] in
            if let appModel {
                Group {
                    if let channel = appModel.selectedChannel, channel.type == .forum {
                        NavigationLazyView(ForumChannelList(forumChannel: channel))
                    } else {
                        ChannelView(self.$appModel.selectedChannel, appModel.selectedChannel?.guild_name ?? "Accord")
                            .onAppear {
                                if let channel = appModel.selectedChannel {
                                    let channelID = channel.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [channelID] in
                                        if appModel.selectedChannel?.id == channelID {
                                            channel.read_state?.mention_count = 0
                                            channel.read_state?.last_message_id = channel.last_message_id
                                        }
                                    })
                                }
                            }
                            .onDisappear {
                                if let channel = appModel.selectedChannel {
                                    channel.read_state?.mention_count = 0
                                    channel.read_state?.last_message_id = channel.last_message_id
                                }
                            }
                    }
                }
            }
        })
        .environmentObject(self.appModel)
        .environmentObject(self.discordSettings)
        .environmentObject(self.userGuildSettings)
        .preferredColorScheme({
            if self.discordColorScheme {
                return self.discordSettings.theme == .dark ? .dark : .light
            } else {
                return nil
            }
        }())
        .sheet(isPresented: $popup, onDismiss: {}) {
            SearchView()
                .focusable()
                .environmentObject(self.appModel)
                .touchBar {
                    Button(action: {
                        popup.toggle()
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Refresh")), perform: { pub in
            guard let uInfo = pub.userInfo as? [String: Int],
                  let firstKey = uInfo.first else { return }
            print(firstKey)
            self.selectedServer = firstKey.key
            self.appModel.selectedGuild = Array(appModel.folders.map(\.guilds).joined())[keyed: firstKey.key]
            self.appModel.selectedChannel = self.appModel.selectedGuild?.channels.first(where: { $0.id == String(firstKey.value) })
        })
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DMSelect")), perform: { pub in
            guard let uInfo = pub.userInfo as? [String: String],
                  let index = uInfo["index"], let number = Int(index) else { return }
            self.selectedServer = "@me"
            self.appModel.selectedChannel = self.appModel.privateChannels.first(where: { $0.id == String(number) })
        })
        .onReceive(NotificationCenter.default.publisher(for: .init("red.evelyn.accord.Search")), perform: { _ in
            self.popup.toggle()
        })
        .onAppear {
            if let upcomingGuild = self.viewModel.upcomingGuild {
                self.appModel.selectedGuild = upcomingGuild
                //self.selectedChannel.wrappedValue = self.viewModel.upcomingSelection
            }
            DispatchQueue.global().async {
                try? wss?.updatePresence(status: MediaRemoteWrapper.status ?? "offline", since: 0) {
                    Activity.current!
                }
                if UserDefaults.standard.bool(forKey: "XcodeRPC") {
                    guard let workspace = XcodeRPC.getActiveWorkspace() else { return }
                    XcodeRPC.updatePresence(workspace: workspace, filename: XcodeRPC.getActiveFilename())
                } else if UserDefaults.standard.bool(forKey: "AppleMusicRPC") {
                    MediaRemoteWrapper.updatePresence()
                } else if UserDefaults.standard.bool(forKey: "VSCodeRPCEnabled") {
                    VisualStudioCodeRPC.updatePresence()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                if self.appModel.selectedChannel == nil {
                    Toggle(isOn: Binding.constant(false)) {
                        Image(systemName: "bell.badge.fill")
                    }
                }
            }
        }
    }
}

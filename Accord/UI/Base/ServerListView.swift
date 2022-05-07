//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import Combine
import SwiftUI

public var roleColors: [String: (Int, Int)] = [:]
public var roleNames: [String: String] = [:]

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

enum Emotes {
    public static var emotes: [String: [DiscordEmote]] = [:] {
        didSet {
            print(#function)
        }
    }
}

func pingCount(guild: Guild) -> Int {
    let intArray = guild.channels!.compactMap { $0.read_state?.mention_count }
    return intArray.reduce(0, +)
}

func unreadMessages(guild: Guild) -> Bool {
    let array = guild.channels?
        .compactMap { $0.last_message_id == $0.read_state?.last_message_id }
        .contains(false)
    return array ?? false
}

struct ServerListView: View {
    // i feel bad about this but i need some way to use static vars
    public class UpdateView: ObservableObject {
        @Published var updater: Bool = false
        func updateView() {
            DispatchQueue.main.async {
                self.updater.toggle()
                self.objectWillChange.send()
            }
        }
    }

    @State var selection: Int?
    @State var selectedGuild: Guild?
    @State var selectedServer: Int? = 0
    public static var folders: [GuildFolder] = .init()
    public static var privateChannels: [Channel] = .init()
    public static var mergedMembers: [String:Guild.MergedMember] = .init()
    internal static var readStates: [ReadStateEntry] = .init()
    var statusText: String?
    @State var status: String?
    @State var timedOut: Bool = false
    @State var mentions: Bool = false
    @State var bag = Set<AnyCancellable>()
    @StateObject var viewUpdater = UpdateView()
    @State var iconHovered: Bool = false

    var dmButton: some View {
        Button(action: {
            selection = nil
            DispatchQueue.global().async {
                wss?.cachedMemberRequest.removeAll()
                ServerListView.privateChannels = ServerListView.privateChannels.sorted(by: { $0.last_message_id ?? "" > $1.last_message_id ?? "" })
            }
            selectedServer = 201
        }) {
            Image(systemName: "bubble.right.fill")
                .imageScale(.medium)
                .frame(width: 45, height: 45)
                .background(selectedServer == 201 ? Color.accentColor.opacity(0.5) : Color(NSColor.windowBackgroundColor))
                .cornerRadius(iconHovered || selectedServer == 201 ? 15.0 : 23.5)
                .if(selectedServer == 201, transform: { $0.foregroundColor(Color.white) })
                .onHover(perform: { self.iconHovered = $0 })
        }
    }

    var onlineButton: some View {
        Button("Offline") {
            AccordApp.error(text: "Offline", additionalDescription: "Check your network connection")
        }
    }

    @ViewBuilder
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

    var settingsLink: some View {
        NavigationLink(destination: SettingsView(), tag: 0, selection: self.$selection) {
            HStack {
                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .cornerRadius((self.selection == 0) ? 15.0 : 23.5)
                    statusIndicator
                }
                VStack(alignment: .leading) {
                    if let user = AccordCoreVars.user {
                        Text(user.username) + Text("#" + user.discriminator).foregroundColor(.secondary)
                        if let statusText = statusText {
                            Text(statusText)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }

        }
        .buttonStyle(BorderlessButtonStyle())
    }

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Messages button

                    LazyVStack {
                        if !NetworkCore.shared.connected {
                            onlineButton
                                .buttonStyle(BorderlessButtonStyle())
                        }
                        ZStack(alignment: .bottomTrailing) {
                            dmButton
                            if let count = Self.privateChannels.compactMap({ $0.read_state?.mention_count }).reduce(0, +), count != 0 {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.red)
                                        .frame(width: 15, height: 15)
                                    Text(String(count))
                                        .foregroundColor(Color.white)
                                        .fontWeight(.semibold)
                                        .font(.caption)
                                }
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        Color.gray
                            .frame(height: 1)
                            .opacity(0.75)
                            .padding(.horizontal)
                        FolderListView(selectedServer: self.$selectedServer, selection: self.$selection, selectedGuild: self.$selectedGuild, updater: self.viewUpdater)
                            .padding(.trailing, 3.5)
                        Color.gray
                            .frame(height: 1)
                            .opacity(0.75)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .frame(width: 80)
                .padding(.top, 5)
                Divider()

                // MARK: - Loading UI

                if selectedServer == 201 {
                    List {
                        settingsLink
                        Divider()
                        ForEach(Self.privateChannels, id: \.id) { channel in
                            NavigationLink(destination: NavigationLazyView(ChannelView(channel).equatable()), tag: Int(channel.id) ?? 0, selection: self.$selection) {
                                ServerListViewCell(channel: channel, updater: self.viewUpdater)
                                    .onChange(of: self.selection, perform: { _ in
                                        if self.selection == Int(channel.id) {
                                            channel.read_state?.mention_count = 0
                                            channel.read_state?.last_message_id = channel.last_message_id
                                        }
                                    })
                            }
                            .contextMenu {
                                Button("Copy Channel ID") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(channel.id, forType: .string)
                                }
                                Button("Close DM") {
                                    let headers = Headers(
                                        userAgent: discordUserAgent,
                                        contentType: nil,
                                        token: AccordCoreVars.token,
                                        type: .DELETE,
                                        discordHeaders: true,
                                        referer: "https://discord.com/channels/@me",
                                        empty: true
                                    )
                                    Request.ping(url: URL(string: "\(rootURL)/channels/\(channel.id)"), headers: headers)
                                    guard let index = ServerListView.privateChannels.generateKeyMap()[channel.id] else { return }
                                    ServerListView.privateChannels.remove(at: index)
                                }
                                Button("Mark as read") {
                                    channel.read_state?.mention_count = 0
                                    channel.read_state?.last_message_id = channel.last_message_id
                                }
                                Button("Open in new window") {
                                    showWindow(channel)
                                }
                            }
                        }
                    }
                    .padding(.top, 5)
                    .listStyle(.sidebar)
                } else if let selectedGuild = selectedGuild {
                    GuildView(guild: selectedGuild, selection: self.$selection, updater: self.viewUpdater)
                        .animation(nil, value: UUID())
                }
            }
            .frame(minWidth: 300, maxWidth: 500, maxHeight: .infinity)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Refresh")), perform: { pub in
            guard let uInfo = pub.userInfo as? [Int: Int],
                  let firstKey = uInfo.first else { return }
            print(firstKey)
            self.selectedServer = firstKey.key
            self.selection = firstKey.value
            self.selectedGuild = Array(Self.folders.map(\.guilds).joined())[firstKey.key]
        })
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DMSelect")), perform: { pub in
            guard let uInfo = pub.userInfo as? [String: String],
                  let index = uInfo["index"], let number = Int(index) else { return }
            self.selectedServer = 201
            self.selection = number
        })
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Updater")), perform: { _ in
            viewUpdater.updateView()
        })
        .onAppear {
            self.selectedGuild = ServerListView.folders.first?.guilds.first
            DispatchQueue.global().async {
                if !Self.folders.isEmpty {
                    let val = UserDefaults.standard.integer(forKey: "AccordChannelIn\(Array(Self.folders.compactMap { $0.guilds }.joined())[0].id)")
                    DispatchQueue.main.async {
                        self.selection = (val != 0 ? val : nil)
                    }
                }
                Request.fetch([Channel].self, url: URL(string: "\(rootURL)/users/@me/channels"), headers: standardHeaders) { completion in
                    switch completion {
                    case let .success(channels):
                        let channels = channels.sorted { $0.last_message_id ?? "" > $1.last_message_id ?? "" }
                        DispatchQueue.main.async {
                            Self.privateChannels = channels
                            DispatchQueue.global().async {
                                assignPrivateReadStates()
                                self.viewUpdater.updateView()
                            }
                        }
                        Notifications.privateChannels = Self.privateChannels.map(\.id)
                    case let .failure(error):
                        print(error)
                    }
                }
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
                if selection == nil {
                    Toggle(isOn: Binding.constant(false)) {
                        Image(systemName: "bell.badge.fill")
                    }
                    .hidden()
                }
            }
        }
    }
}

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
    @State var selectedServer: Int? = 0
    public static var folders: [GuildFolder] = .init()
    public static var privateChannels: [Channel] = .init()
    public static var mergedMembers: [String:Guild.MergedMember] = .init()
    internal static var readStates: [ReadStateEntry] = .init()
    @State var status: String?
    @State var timedOut: Bool = false
    @State var mentions: Bool = false
    @State var bag = Set<AnyCancellable>()
    @StateObject var viewUpdater = UpdateView()

    var dmButton: some View {
        Button(action: {
            selectedServer = 201
            selection = nil
            wss?.cachedMemberRequest.removeAll()
        }) {
            Image(systemName: "bubble.left.fill")
                .frame(width: 45, height: 45)
                .background(VisualEffectView(material: .fullScreenUI, blendingMode: .withinWindow))
                .cornerRadius(selectedServer == 201 ? 15.0 : 23.5)
        }
    }

    var onlineButton: some View {
        Button("Offline") {
            AccordApp.error(text: "Offline", additionalDescription: "Check your network connection")
        }
    }

    @ViewBuilder
    var statusIndicator: some View {
        switch self.status {
        case "online":
            Circle()
                .foregroundColor(Color.green)
                .frame(width: 12, height: 12)
        case "invisible":
            Image("invisible")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
        case "dnd":
            Image("dnd")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
        case "idle":
            Circle()
                .foregroundColor(Color(NSColor.systemOrange))
                .frame(width: 12, height: 12)
        default:
            Circle()
                .foregroundColor(Color.clear)
                .frame(width: 12, height: 12)
        }
    }

    var settingsLink: some View {
        NavigationLink(destination: NavigationLazyView(SettingsViewRedesign()), tag: 0, selection: self.$selection) {
            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .cornerRadius((self.selection == 0) ? 15.0 : 23.5)
                statusIndicator
            }
        }
    }

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Messages button

                    LazyVStack {
                        if !NetworkCore.shared.connected {
                            onlineButton
                        }
                        ZStack(alignment: .bottomTrailing) {
                            dmButton
                            if Self.privateChannels.compactMap({ $0.read_state?.mention_count }).reduce(0, +) != 0 {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.red)
                                        .frame(width: 15, height: 15)
                                    Text(String(Self.privateChannels.compactMap { $0.read_state?.mention_count }.reduce(0, +)))
                                        .foregroundColor(Color.white)
                                        .fontWeight(.semibold)
                                        .font(.caption)
                                }
                            }
                        }
                        Color.gray
                            .frame(height: 1)
                            .opacity(0.75)
                            .padding(.horizontal)
                        FolderListView(selectedServer: self.$selectedServer, selection: self.$selection, updater: self.viewUpdater)
                            .padding(.trailing, 3.5)
                        Color.gray
                            .frame(height: 1)
                            .opacity(0.75)
                            .padding(.horizontal)
                        settingsLink
                    }
                    .padding(.vertical)
                }
                .buttonStyle(BorderlessButtonStyle())
                .frame(width: 80)
                .padding(.top, 5)
                Divider()

                // MARK: - Loading UI

                if selectedServer == 201 {
                    List {
                        Text("Messages")
                            .fontWeight(.bold)
                            .font(.title2)
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
                                Button(action: {
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
                                }) {
                                    Text("Close DM")
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
                        }
                    }
                    .padding(.top, 5)
                    .listStyle(.sidebar)
                } else if let selected = selectedServer {
                    GuildView(guild: Array(Self.folders.compactMap { $0.guilds }.joined())[selected], selection: self.$selection, updater: self.viewUpdater)
                        .animation(nil, value: UUID())
                }
            }
            .frame(minWidth: 300, maxWidth: 500, maxHeight: .infinity)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Refresh")), perform: { pub in
            guard let uInfo = pub.userInfo as? [Int: Int],
                  let firstKey = uInfo.first else { return }
            self.selectedServer = firstKey.key
            self.selection = firstKey.value
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
            concurrentQueue.async {
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
                            concurrentQueue.async {
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

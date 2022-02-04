//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import Combine
import SwiftUI

public var roleColors: [String: (Int, Int)] = [:]

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
    public static var emotes: [String: [DiscordEmote]] = [:]
}

func pingCount(guild: Guild) -> Int {
    let intArray = guild.channels!.compactMap { $0.read_state?.mention_count }
    return intArray.reduce(0, +)
}

struct ServerListView: View {
    init(full: GatewayD?) {
        var full = full
        status = full?.user_settings?.status
        guard Self.folders.isEmpty else {
            return
        }
        MediaRemoteWrapper.status = full?.user_settings?.status
        Activity.current = Activity(
            emoji: StatusEmoji(
                name: full?.user_settings?.custom_status?.emoji_name ?? "",
                id: full?.user_settings?.custom_status?.emoji_id ?? "",
                animated: false
            ),
            name: "Custom Status",
            type: 4
        )
        Emotes.emotes = full?.guilds
            .map { ["\($0.id)$\($0.name)": $0.emojis] }
            .flatMap { $0 }
            .reduce([String: [DiscordEmote]]()) { dict, tuple in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            } ?? [:]
        assignReadStates(full: &full)
        order(full: &full)
        var guildOrder = full?.user_settings?.guild_positions ?? []
        var folderTemp = full?.user_settings?.guild_folders ?? []
        full?.guilds.forEach { guild in
            if !guildOrder.contains(guild.id) {
                guildOrder.insert(guild.id, at: 0)
                folderTemp.insert(GuildFolder(id: nil, name: nil, color: nil, guild_ids: [guild.id]), at: 0)
            }
        }
        let messageDict = full?.guilds.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        } ?? [:]
        let guildTemp = guildOrder.compactMap { messageDict[$0] }.compactMap { full?.guilds[$0] }
        let guildDict = guildTemp.enumerated().compactMap { index, element in
            [element.id: index]
        }.reduce(into: [:]) { result, next in
            result.merge(next) { _, rhs in rhs }
        }
        for folder in folderTemp {
            for id in folder.guild_ids.compactMap({ guildDict[$0] }) {
                var guild = guildTemp[id]
                guild.emojis.removeAll()
                guild.index = id
                for channel in 0 ..< (guild.channels?.count ?? 0) {
                    guild.channels?[channel].guild_id = guild.id
                    guild.channels?[channel].guild_icon = guild.icon
                    guild.channels?[channel].guild_name = guild.name
                }
                folder.guilds.append(guild)
            }
        }
        Self.folders = folderTemp
        Self.readStates = full?.read_state?.entries ?? []
        selection = nil
        concurrentQueue.async {
            guard let guilds = full?.guilds else { return }
            roleColors = RoleManager.arrangeRoleColors(guilds: guilds)
        }
        MentionSender.shared.delegate = self
    }

    @State var selection: Int?
    @State var selectedServer: Int? = 0
    @State var online: Bool = true
    @State var alert: Bool = true
    public static var folders: [GuildFolder] = []
    public static var privateChannels: [Channel] = []
    internal static var readStates: [ReadStateEntry] = []
    @State var status: String?
    @State var timedOut: Bool = false
    @State var mentions: Bool = false
    @State var bag = Set<AnyCancellable>()
    @State var updater: Bool = false

    var body: some View {
        lazy var dmButton = Button(action: {
            wss?.cachedMemberRequest.removeAll()
            selectedServer = 201
            selection = nil
        }) {
            Image(systemName: "bubble.left.fill")
                .frame(width: 45, height: 45)
                .background(VisualEffectView(material: .fullScreenUI, blendingMode: .withinWindow))
                .cornerRadius(selectedServer == 999 ? 15.0 : 23.5)
        }
        lazy var onlineButton: some View = Button("Offline") {
            alert.toggle()
        }
        .alert(isPresented: $alert) {
            Alert(
                title: Text("Could not connect"),
                message: Text("There was an error connecting to Discord"),
                primaryButton: .default(
                    Text("Ok"),
                    action: {
                        alert.toggle()
                    }
                ),
                secondaryButton: .destructive(
                    Text("Reconnect"),
                    action: {
                        if let wss = wss {
                            wss.reset()
                        } else {
                            concurrentQueue.async {
                                guard let new = try? Gateway(url: Gateway.gatewayURL) else { return }
                                new.ready().sink(receiveCompletion: doNothing, receiveValue: doNothing).store(in: &new.bag)
                                wss = new
                            }
                        }
                    }
                )
            )
        }
        lazy var foldersList: some View = {
            ForEach(Self.folders, id: \.hashValue) { folder in
                if folder.guilds.count != 1 {
                    Folder(icon: Array(folder.guilds.prefix(4)), color: NSColor.color(from: folder.color ?? 0) ?? NSColor.windowBackgroundColor) {
                        ForEach(folder.guilds, id: \.hashValue) { guild in
                            ZStack(alignment: .bottomTrailing) {
                                Button(action: { [weak wss] in
                                    wss?.cachedMemberRequest.removeAll()
                                    if selectedServer == 201 {
                                        selectedServer = guild.index
                                    } else {
                                        withAnimation {
                                            selectedServer = guild.index
                                        }
                                    }
                                }) {
                                    Attachment(iconURL(guild.id, guild.icon ?? "")).equatable()
                                        .frame(width: 45, height: 45)
                                        .cornerRadius(selectedServer == guild.index ? 15.0 : 23.5)
                                }
                                if pingCount(guild: guild) != 0 {
                                    ZStack {
                                        Circle()
                                            .foregroundColor(Color.red)
                                            .frame(width: 15, height: 15)
                                        Text(String(pingCount(guild: guild)))
                                            .foregroundColor(Color.white)
                                            .fontWeight(.semibold)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 1)
            } else {
                ZStack(alignment: .bottomTrailing) {
                    ForEach(folder.guilds, id: \.hashValue) { guild in
                        Button(action: { [weak wss] in
                            wss?.cachedMemberRequest.removeAll()
                            if selectedServer == 201 {
                                selectedServer = guild.index
                            } else {
                                withAnimation {
                                    selectedServer = guild.index
                                }
                            }
                        }) {
                            Attachment(iconURL(guild.id, guild.icon ?? ""), size: nil).equatable()
                                .frame(width: 45, height: 45)
                                .cornerRadius((selectedServer == guild.index) ? 15.0 : 23.5)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        if pingCount(guild: guild) != 0 {
                            ZStack {
                                Circle()
                                    .foregroundColor(Color.red)
                                    .frame(width: 15, height: 15)
                                Text(String(pingCount(guild: guild)))
                                    .foregroundColor(Color.white)
                                    .fontWeight(.semibold)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }

        }()
        lazy var statusIndicator: some View = Group {
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
        lazy var settingsLink: some View = NavigationLink(destination: NavigationLazyView(SettingsViewRedesign()), tag: 1, selection: self.$selection) {
            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 45, height: 45)
                statusIndicator
            }
        }
        return NavigationView {
            HStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Messages button
                    LazyVStack {
                        if !online || !NetworkCore.shared.connected {
                            onlineButton
                        }
                        dmButton
                        foldersList
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
                                ServerListViewCell(channel: channel)
                                    .onChange(of: self.selection, perform: { _ in
                                        if self.selection == Int(channel.id) {
                                            channel.read_state?.mention_count = 0
                                            channel.read_state?.last_message_id = channel.last_message_id
                                        }
                                    })
                            }
                        }
                    }
                    .padding(.top, 5)
                    .listStyle(.sidebar)
                } else if let selected = selectedServer {
                    GuildView(guild: Array(Self.folders.compactMap { $0.guilds }.joined())[selected], selection: self.$selection)
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
        .onChange(of: selectedServer, perform: { [selectedServer] new in
            concurrentQueue.async {
                print("selected")
                let map = Array(Self.folders.compactMap { $0.guilds }.joined())
                guard let selectedServer = selectedServer,
                      new != 201,
                      let new = new,
                      let id = map[safe: selectedServer]?.id,
                      let newID = map[safe: new]?.id else { return }
                print("selected new at id", newID, id)
                UserDefaults.standard.set(self.selection, forKey: "AccordChannelIn\(id)")
                let val = UserDefaults.standard.integer(forKey: "AccordChannelIn\(newID)")
                DispatchQueue.main.async {
                    if val != 0 {
                        self.selection = val
                    }
                }
            }
        })
        .onAppear {
            if !Self.folders.isEmpty {
                let val = UserDefaults.standard.integer(forKey: "AccordChannelIn\(Array(Self.folders.compactMap { $0.guilds }.joined())[0].id)")
                self.selection = (val != 0 ? val : nil)
            }
            concurrentQueue.async {
                Request.fetch([Channel].self, url: URL(string: "\(rootURL)/users/@me/channels"), headers: standardHeaders) { channels, error in
                    if let channels = channels {
                        let channels = channels.sorted { $0.last_message_id ?? "" > $1.last_message_id ?? "" }
                        DispatchQueue.main.async {
                            Self.privateChannels = channels
                            concurrentQueue.async {
                                assignPrivateReadStates()
                            }
                        }
                        Notifications.privateChannels = Self.privateChannels.map(\.id)
                    } else if let error = error {
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

//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import SwiftUI


public var roleColors: [String:(Int, Int)] = [:]

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

final class AllEmotes {
    static var shared = AllEmotes()
    var allEmotes: [String:[DiscordEmote]] = [:]
}

func pingCount(guild: Guild) -> Int {
    let intArray = guild.channels!.compactMap { $0.read_state?.mention_count }
    return intArray.reduce(0, +)
}

struct ServerListView: View {
    
    @State var guilds = [Guild]()
    @Binding var full: GatewayD?
    @State var selection: Int? = nil
    @State var selectedServer: Int? = nil
    @State var privateChannels = [Channel]()
    @State var guildOrder: [String] = []
    @State var guildIcons: [String:NSImage] = [:]
    @State var pings: [(String, String)] = []
    @State var stuffSelection: Int? = nil
    @State var online: Bool = true
    @State var alert: Bool = true
    @State var folders = [GuildFolder]()
    @State var status: String? = nil
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0, content: {
                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Messages button
                    VStack {
                        if !online {
                            Button("Error") {
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
                                            wss.reset()
                                        }
                                    )
                                )
                            }
                        }
                        if #available(macOS 12.0, *) {
                            Image(systemName: "bubble.left.fill")
                                .frame(width: 45, height: 45)
                                .background(Material.thick)
                                .cornerRadius((selectedServer ?? 0) == 999 ? 15.0 : 23.5)
                                .onTapGesture(count: 1, perform: {
                                    selectedServer = 999
                                })
                        } else {
                            Image(systemName: "bubble.left.fill")
                                .frame(width: 45, height: 45)
                                .background(Color(NSColor.windowBackgroundColor))
                                .cornerRadius((selectedServer ?? 0) == 999 ? 15.0 : 23.5)
                                .onTapGesture(count: 1, perform: {
                                    selectedServer = 999
                                })
                        }
                        // MARK: - Guild icon UI
                        ForEach(folders, id: \.hashValue) { folder in
                            if folder.guilds.count != 1 {
                                Folder(color: NSColor.color(from: folder.color ?? 0) ?? NSColor.windowBackgroundColor) {
                                    ForEach(folder.guilds, id: \.hashValue) { guild in
                                        ZStack(alignment: .bottomTrailing) {
                                            Button(action: { [weak guild] in
                                                withAnimation {
                                                    DispatchQueue.main.async {
                                                        selectedServer = guild?.index
                                                    }
                                                }
                                            }) { [weak guild] in
                                                Attachment(iconURL(guild?.id ?? "", guild?.icon ?? ""), size: nil)
                                                    .frame(minWidth: 15, idealWidth: 45, minHeight: 15, idealHeight: 45)
                                                    .cornerRadius((selectedServer == guild?.index) ? 15.0 : 23.5)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            if pingCount(guild: guild) != 0 {
                                                ZStack {
                                                    Circle()
                                                        .foregroundColor(Color.red)
                                                        .frame(width: 15, height: 15)
                                                    Text(String(describing: pingCount(guild: guild)))
                                                        .foregroundColor(Color.white)
                                                        .fontWeight(.semibold)
                                                        .font(.caption)
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                ZStack(alignment: .bottomTrailing) {
                                    ForEach(folder.guilds, id: \.hashValue) { guild in
                                        Button(action: { [weak guild] in
                                            withAnimation {
                                                DispatchQueue.main.async {
                                                    selectedServer = guild?.index
                                                }
                                            }
                                        }) { [weak guild] in
                                            Attachment(iconURL(guild?.id ?? "", guild?.icon ?? ""), size: nil)
                                                .frame(width: 45, height: 45)
                                                .cornerRadius((selectedServer == guild?.index) ? 15.0 : 23.5)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        if pingCount(guild: guild) != 0 {
                                            ZStack {
                                                Circle()
                                                    .foregroundColor(Color.red)
                                                    .frame(width: 15, height: 15)
                                                Text(String(describing: pingCount(guild: guild)))
                                                    .foregroundColor(Color.white)
                                                    .fontWeight(.semibold)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if !(folders.isEmpty) {
                            NavigationLink(destination: NavigationLazyView(SettingsViewRedesign()), tag: 1, selection: self.$stuffSelection) {
                                ZStack(alignment: .bottomTrailing) {
                                    Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                                        .scaledToFit()
                                        .cornerRadius((selectedServer ?? 0) == 9999 ? 15.0 : 23.5)
                                        .frame(width: 45, height: 45)
                                    switch self.status {
                                    case "online":
                                        Circle()
                                            .foregroundColor(Color(NSColor.systemGreen))
                                            .frame(width: 12, height: 12)
                                    case "invisible":
                                        Circle()
                                            .foregroundColor(Color(NSColor.systemGray))
                                            .frame(width: 12, height: 12)
                                    case "dnd":
                                        Circle()
                                            .foregroundColor(Color(NSColor.systemRed))
                                            .frame(width: 12, height: 12)
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
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical)
                }
                .frame(width: 80)
                .buttonStyle(BorderlessButtonStyle())
                .padding(.top, 5)
                Divider()
                // MARK: - Loading UI
                if selectedServer == 999 {
                    // MARK: - Private channels (DMs)
                    List {
                        Text("Messages")
                            .fontWeight(.bold)
                            .font(.title2)
                        Divider()
                        ForEach(privateChannels, id: \.id) { channel in
                            NavigationLink(destination: NavigationLazyView(ChannelView(channel).equatable()), tag: (Int(channel.id) ?? 0), selection: $selection) {
                                ServerListViewCell(channel: channel)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(.top, 5)
                } else if !(guilds.isEmpty) {
                    // MARK: - Guild channels
                    GuildView(guild: Binding.constant((Array(folders.compactMap { $0.guilds }.joined()))[selectedServer ?? 0]), selection: self.$selection)
                }
            })
            .frame(minWidth: 300, maxWidth: 500, maxHeight: .infinity)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("READY"))) { notif in
            status = full?.user_settings?.status
            concurrentQueue.async {
                Request.fetch([Channel].self, url: URL(string: "https://discordapp.com/api/users/@me/channels"), headers: standardHeaders) { channels, error in
                    if let channels = channels {
                        let channels = channels.sorted { $0.last_message_id ?? "" > $1.last_message_id ?? "" }
                        DispatchQueue.main.async {
                            self.privateChannels = channels
                        }
                        Notifications.shared.privateChannels = privateChannels.map { $0.id }
                    } else if let error = error {
                        releaseModePrint(error)
                    }
                }
            }
            var guilds = full?.guilds ?? []
            MentionSender.shared.delegate = self
            DispatchQueue(label: "shitcode queue", attributes: .concurrent).async {
                assignReadStates()
            }
            AllEmotes.shared.allEmotes = guilds.map { ["\($0.id)$\($0.name)":$0.emojis] }
                                            .flatMap { $0 }
                                            .reduce([String:[DiscordEmote]]()) { (dict, tuple) in
                                                var nextDict = dict
                                                nextDict.updateValue(tuple.1, forKey: tuple.0)
                                                return nextDict
                                            }
            if sortByMostRecent {
                guilds.sort { ($0.channels ?? []).sorted(by: {$0.last_message_id ?? "" > $1.last_message_id ?? ""})[0].last_message_id ?? "" > ($1.channels ?? []).sorted(by: {$0.last_message_id ?? "" > $1.last_message_id ?? ""})[0].last_message_id ?? "" }
                self.guilds = guilds
            } else {
                let guildOrder = full?.user_settings?.guild_positions ?? []
                let messageDict = guilds.enumerated().compactMap { (index, element) in
                    return [element.id:index]
                }.reduce(into: [:]) { (result, next) in
                    result.merge(next) { (_, rhs) in rhs }
                }
                var guildTemp = [Guild]()
                for item in guildOrder {
                    if let first = messageDict[item] {
                        let guild = guilds[first]
                        for channel in guild.channels ?? [] {
                            channel.guild_id = guild.id
                        }
                        guildTemp.append(guild)
                    }
                }
                self.guilds = guildTemp
                let guildDict = guildTemp.enumerated().compactMap { (index, element) in
                    return [element.id:index]
                }.reduce(into: [:]) { (result, next) in
                    result.merge(next) { (_, rhs) in rhs }
                }
                let folderTemp = full?.user_settings?.guild_folders ?? []
                for folder in folderTemp {
                    for id in folder.guild_ids {
                        if let guildIndex = guildDict[id] {
                            let guild = guildTemp[guildIndex]
                            guild.index = guildIndex
                            folder.guilds.append(guild)
                        }
                    }
                }
                self.folders = folderTemp
            }
            concurrentQueue.async {
                order()
            }
            DispatchQueue.main.async {
                selectedServer = 0
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SETUP_DONE"), object: nil)
                full = nil
            }
            concurrentQueue.async {
                roleColors = RoleManager.shared.arrangeRoleColors(guilds: guilds)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Notification"))) { notif in
            pings.append((notif.userInfo as! [String:Any])["info"] as! (String, String))
        }
    }
}

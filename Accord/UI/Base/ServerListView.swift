//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import SwiftUI


public var roleColors: [String:(Int, Int, NSColor?)] = [:]

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
    var body: some View {
        NavigationView {
            HStack(spacing: 0, content: {
                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Messages button
                    LazyVStack {
                        ZStack {
                            Color.primary.colorInvert()
                            Image(systemName: "bubble.left.fill")
                        }
                        .frame(width: 45, height: 45)
                        .cornerRadius((selectedServer ?? 0) == 999 ? 15.0 : 23.5)
                        .onTapGesture(count: 1, perform: {
                            selectedServer = 999
                        })
                        // MARK: - Guild icon UI
                        ForEach(Array(zip(guilds.indices, guilds)), id: \.1.id) { offset, guild in
                            ZStack(alignment: .bottomTrailing) {
                                Button(action: {
                                    withAnimation {
                                        DispatchQueue.main.async {
                                            selectedServer = offset
                                        }
                                    }
                                }) { [weak guild] in
                                    Attachment(iconURL(guild?.id ?? "", guild?.icon ?? ""))
                                        .frame(width: 45, height: 45)
                                        .cornerRadius(((selectedServer ?? 0) == offset) ? 15.0 : 23.5)
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
                                } else {
                                }
                            }

                        }
                        NavigationLink(destination: SettingsViewRedesign(), tag: 1, selection: self.$stuffSelection) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                                    .scaledToFit()
                                    .cornerRadius((selectedServer ?? 0) == 9999 ? 15.0 : 23.5)
                                    .frame(width: 45, height: 45)
                                Circle()
                                    .foregroundColor(Color.green.opacity(0.75))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(width: 80)
                .buttonStyle(BorderlessButtonStyle())
                .padding(.top, 5)
                Divider()
                // MARK: - Loading UI
                if selectedServer == nil {
                    VStack {
                        Text("Connecting...")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear(perform: {
                            let privChannelQueue = DispatchQueue(label: "Private Channel Loading Queue", attributes: .concurrent)
                            privChannelQueue.async {
                                Networking<[Channel]>().fetch(url: URL(string: "https://discordapp.com/api/users/@me/channels"), headers: standardHeaders) { channels in
                                    if let channels = channels {
                                        privateChannels = channels.sorted { $0.last_message_id ?? "" > $1.last_message_id ?? "" }
                                        Notifications.shared.privateChannels = privateChannels.map { $0.id }
                                    }
                                }
                            }
                        })
                    }
                } else if selectedServer == 999 {
                    // MARK: - Private channels (DMs)
                    HStack {
                        List {
                            Text("Messages")
                                .fontWeight(.bold)
                                .font(.title2)
                            Divider()
                            ForEach(privateChannels, id: \.id) { channel in
                                NavigationLink(destination: NavigationLazyView(GuildView(guildID: "@me", channelID: channel.id, channelName: channel.name ?? "").equatable()), tag: (Int(channel.id) ?? 0), selection: self.$selection) {
                                    HStack {
                                        Image(systemName: "number") // normal channel
                                        Text(channel.name ?? channel.recipients?[0].username ?? "")
                                        Spacer()

                                        if let readState = channel.read_state {
                                            if readState.mention_count != 0 {
                                                ZStack {
                                                    Circle()
                                                        .foregroundColor(Color.red)
                                                        .frame(width: 15, height: 15)
                                                    Text(String(describing: readState.mention_count))
                                                        .foregroundColor(Color.white)
                                                        .fontWeight(.semibold)
                                                        .font(.caption)
                                                }
                                            }
                                        }
                                        Button(action: {
                                            showWindow(guildID: "@me", channelID: channel.id, channelName: channel.name ?? "")
                                        }) {
                                            Image(systemName: "arrow.up.right.circle")
                                        }
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())

                            }
                        }
                    }
                    .padding(.top, 5)
                } else {
                    // MARK: - Guild channels
                    if guilds.isEmpty == false {
                        List {
                            if let channels = guilds[selectedServer ?? 0].channels!.enumerated().reversed().reversed() {
                                ForEach(channels, id: \.offset) { offset, section in
                                    if section.type == .section {
                                        Section(header: Text(section.name ?? "")) {
                                            ForEach(channels, id: \.offset) { offset, channel in
                                                if channel.type != .section {
                                                    if channel.parent_id ?? "no" == section.id {
                                                        NavigationLink(destination: NavigationLazyView(GuildView(guildID: (guilds[selectedServer ?? 0].id), channelID: channel.id, channelName: channel.name).equatable()), tag: (Int(channel.id) ?? 0), selection: self.$selection) { [weak channel] in
                                                            HStack {
                                                                switch channel!.type {
                                                                case .normal:
                                                                    Image(systemName: "number") // normal channel
                                                                case .voice:
                                                                    Image(systemName: "speaker.wave.2.fill") // voice chat
                                                                case .guild_news:
                                                                    Image(systemName: "megaphone.fill") // announcement channel
                                                                case .stage:
                                                                    Image(systemName: "person.2.fill") // stages
                                                                default:
                                                                    Image(systemName: "camera.metering.unknown") // unknown
                                                                }
                                                                Text(channel?.name ?? "")
                                                                Spacer()

                                                                Button(action: {
                                                                    channel?.read_state!.mention_count = 0
                                                                }) {
                                                                    if let readState = channel?.read_state {
                                                                        if readState.mention_count != 0 {
                                                                            ZStack {
                                                                                Circle()
                                                                                    .foregroundColor(Color.red)
                                                                                    .frame(width: 15, height: 15)
                                                                                Text(String(describing: readState.mention_count))
                                                                                    .foregroundColor(Color.white)
                                                                                    .fontWeight(.semibold)
                                                                                    .font(.caption)
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                Button(action: {
                                                                    showWindow(guildID: (guilds[selectedServer ?? 0].id), channelID: channel?.id ?? "", channelName: channel?.name ?? "")
                                                                }) {
                                                                    Image(systemName: "arrow.up.right.circle")
                                                                }
                                                            }
                                                        }
                                                        .buttonStyle(BorderlessButtonStyle())
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 5)
                    }
                }
            })
        }

        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("READY"))) { notif in
            self.guilds = full?.guilds ?? []
            imageQueue.async {
                ImageHandling.shared?.getServerIcons(array: guilds) { success, icons in
                    if success {
                        guildIcons = icons
                    }
                }
            }
            MentionSender.shared.delegate = self

            let firstIndexQueue = DispatchQueue(label: "shitcode queue", attributes: .concurrent)
            firstIndexQueue.async {
                let readState = full!.read_state!
                for guild in 0..<guilds.count {
                    for channel in guilds[safe: guild]?.channels ?? [] {
                        if channel.type != .section || channel.type != .stage || channel.type != .voice  {
                            if let index = fastIndexEntries(channel.id, array: readState.entries) {
                                channel.read_state = readState.entries[safe: index]
                            }
                        }
                    }
                }
                
                for channel in privateChannels {
                    if channel.type != .section || channel.type != .stage || channel.type != .voice  {
                        if let index = fastIndexEntries(channel.id, array: readState.entries) {
                            channel.read_state = readState.entries[safe: index]
                        }
                    }
                }
            }
            if sortByMostRecent {
                guilds.sort { ($0.channels ?? []).sorted(by: {$0.last_message_id ?? "" > $1.last_message_id ?? ""})[0].last_message_id ?? "" > ($1.channels ?? []).sorted(by: {$0.last_message_id ?? "" > $1.last_message_id ?? ""})[0].last_message_id ?? "" }
            } else {
                guildOrder = full!.user_settings!.guild_positions
                var guildTemp = [Guild]()
                for item in guildOrder {
                    if let first = fastIndexGuild(item, array: guilds) {
                        guildTemp.append(guilds[first])
                    }
                }
                guilds = guildTemp
            }
            selectedServer = 0
            concurrentQueue.async {
                roleColors = (RoleManager.shared?.arrangeRoleColors(guilds: guilds))!
            }
            for i in 0..<guilds.count {
                AllEmotes.shared.allEmotes["\(guilds[i].id)$\(guilds[i].name)"] = guilds[i].emojis
                (guilds[i].channels) = (guilds[i].channels)?.sorted(by: { $1.position ?? 0 > $0.position ?? 0 })
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SETUP_DONE"), object: nil)
                full = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Notification"))) { notif in
            pings.append((notif.userInfo as! [String:Any])["info"] as! (String, String))
        }

        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

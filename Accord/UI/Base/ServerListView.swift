//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import SwiftUI

public var roleColors: [String:(Int, Int)] = [:]

final class AllEmotes {
    static var shared = AllEmotes()
    var allEmotes: [String:[DiscordEmote]] = [:]
}

func pingCount(guild: Guild) -> Int {
    let intArray = guild.channels!.compactMap { $0.read_state?.mention_count }
    return intArray.reduce(0, +)
}


struct ServerListView: View {
    @Binding var guilds: [Guild]
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
                List {
                    // MARK: - Messages button
                    ZStack {
                        Color.primary.colorInvert()
                        Image(systemName: "bubble.left.fill")
                    }
                    .frame(width: 45, height: 45)
                    .cornerRadius((selectedServer ?? 0) == 999 ? 15.0 : 23.5)
                    .onTapGesture(count: 1, perform: {
                        DispatchQueue.main.async {
                            privateChannels = privateChannels.sorted { $0.last_message_id ?? "" > $1.last_message_id ?? "" }
                            selectedServer = 999
                        }
                    })
                    Divider()
                    // MARK: - Guild icon UI
                    ForEach(0..<guilds.count, id: \.self) { index in
                        ZStack(alignment: .bottomTrailing) {
                            Button(action: {
                                withAnimation {
                                    DispatchQueue.main.async {
                                        selectedServer = index
                                    }
                                }
                            }) {
                                Image(nsImage: guildIcons[guilds[index].id] ?? NSImage()).resizable()
                                    .scaledToFit()
                                    .frame(width: 45, height: 45)
                                    .cornerRadius(((selectedServer ?? 0) == index) ? 15.0 : 23.5)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            if pingCount(guild: guilds[index]) != 0 {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.red)
                                        .frame(width: 15, height: 15)
                                    Text(String(describing: pingCount(guild: guilds[index])))
                                        .foregroundColor(Color.white)
                                        .fontWeight(.semibold)
                                        .font(.caption)
                                }
                            } else {
                            }
                        }

                    }
                    Divider()
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
                    #if DEBUG
                    NavigationLink(destination: SocketEventsDisplay(), tag: 2, selection: self.$stuffSelection) {
                        ZStack {
                            Color.primary.colorInvert()
                            Image(systemName: "ant")
                        }
                        .frame(width: 45, height: 45)
                        .cornerRadius(15.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    #endif
                }
                .frame(width: 80)
                .listStyle(SidebarListStyle())
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
                                NetworkHandling.shared.requestData(url: "https://discordapp.com/api/users/@me/channels", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { success, rawData in
                                    if success {
                                        guard let data = try? JSONDecoder().decode([Channel].self, from: rawData ?? Data()) else { return }
                                        privateChannels = data.sorted { $0.last_message_id ?? "" > $1.last_message_id ?? "" }
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
                            ForEach(0..<privateChannels.count, id: \.self) { index in
                                NavigationLink(destination: GuildView(guildID: Binding.constant("@me"), channelID: Binding.constant(privateChannels[index].id), channelName: Binding.constant(((privateChannels[index].recipients ?? []).map { ($0.username) }).map{ "\($0)" }.joined(separator: ", ") )).equatable(), tag: (Int(privateChannels[index].id) ?? 0), selection: self.$selection) {
                                    HStack {
                                        if privateChannels[index].recipients?.count != 1 {
                                            StockAttachment("https://cdn.discordapp.com/channel-icons/\(privateChannels[index].id)/\(privateChannels[index].icon ?? "").png")
                                                .clipShape(Circle())
                                                .frame(width: 25, height: 25)
                                            Text(privateChannels[index].name ?? "")
                                            Spacer()
                                            if let channel = privateChannels[index] {
                                                Button(action: { [weak channel] in
                                                    channel?.read_state!.mention_count = 0
                                                }) { [weak channel] in
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
                                                Button(action: { [weak channel] in
                                                    showWindow(guildID: "@me", channelID: channel?.id ?? "", channelName: ((channel?.recipients ?? []).map { ($0.username) }).map{ "\($0)" }.joined(separator: ", ") )
                                                }) {
                                                    Image(systemName: "arrow.up.right.circle")
                                                }
                                            }

                                        } else {
                                            StockAttachment("https://cdn.discordapp.com/avatars/\(privateChannels[index].recipients![0].id)/\(privateChannels[index].recipients![0].avatar ?? "").png")
                                                .clipShape(Circle())
                                                .frame(width: 25, height: 25)
                                            Text(privateChannels[index].recipients![0].username )
                                            Spacer()
                                            if let channel = privateChannels[index] {
                                                Button(action: { [weak channel] in
                                                    channel?.read_state!.mention_count = 0
                                                }) { [weak channel] in
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
                                                Button(action: { [weak channel] in
                                                    showWindow(guildID: "@me", channelID: channel?.id ?? "", channelName: ((channel?.recipients ?? []).map { ($0.username) }).map{ "\($0)" }.joined(separator: ", ") )
                                                }) {
                                                    Image(systemName: "arrow.up.right.circle")
                                                }
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())

                            }

                        }
                        .listStyle(SidebarListStyle())
                    }
                    .padding(.top, 5)
                } else {
                    // MARK: - Guild channels
                    if guilds.isEmpty == false {
                        List {
                            if let channels = guilds[selectedServer ?? 0].channels {
                                ForEach(Array(channels).enumerated().reversed().reversed(), id: \.offset) { offset, section in
                                    if section.type == .section {
                                        Section(header: Text(section.name ?? "")) {
                                            ForEach(Array(channels).enumerated().reversed().reversed(), id: \.offset) { offset, channel in
                                                if channel.type != .section {
                                                    if channel.parent_id ?? "no" == section.id {
                                                        NavigationLink(destination: GuildView(guildID: Binding.constant((guilds[selectedServer ?? 0].id)), channelID: Binding.constant(channel.id), channelName: Binding.constant(channel.name ?? "")).equatable(), tag: (Int(channel.id) ?? 0), selection: self.$selection) { [weak channel] in
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
                        .listStyle(SidebarListStyle())
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 5)
                    }
                }
            })
        }
        .toolbar {
            if guilds != [] && selectedServer ?? 1000 <= guilds.count {
                HStack {
                    Text(guilds[selectedServer ?? 0].name)
                        .fontWeight(.semibold)
                    Image(nsImage: guildIcons[guilds[selectedServer ?? 0].id] ?? NSImage()).resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .cornerRadius(23.5)
                }
            } else if selectedServer == 999 {
                Text("Direct Messages")
                    .fontWeight(.semibold)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("READY"))) { notif in
            MentionSender.shared.delegate = self
            ImageHandling.shared?.getServerIcons(array: guilds) { success, icons in
                if success {
                    guildIcons = icons
                }
            }
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

                let guildIDs = guilds.map { $0.id }
                var guildTemp = [Guild]()
                for item in guildOrder {
                    if let first = fastIndexGuild(item, array: guilds) {
                        guildTemp.append(guilds[first])
                    }
                }
                guilds = guildTemp
            }
            selectedServer = 0
            print("[Accord] cleaned up")
            concurrentQueue.async {
                roleColors = (RoleManager.shared?.arrangeRoleColors(guilds: guilds))!
            }
            for i in 0..<guilds.count {
                AllEmotes.shared.allEmotes["\(guilds[i].id)$\(guilds[i].name)"] = guilds[i].emojis
//                print(AllEmotes.shared.allEmotes)
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

struct SocketEventsDisplay: View {
    var body: some View {
        List(0..<Array(socketEvents).count, id: \.self) { event in
            if let event = socketEvents.reversed()[event] {
                Divider()
                VStack(alignment: .leading) {
                    Text(Array(event.keys)[0])
                        .fontWeight(.bold)
                    Divider()
                    Text(event[Array(event.keys)[0]] ?? "")
                        .lineLimit(30)
                        .font(.system(.body, design: .monospaced))
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
            }
        }
        .rotationEffect(.radians(.pi))
        .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

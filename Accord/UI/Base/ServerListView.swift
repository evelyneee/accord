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
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0, content: {
                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Messages button
                    LazyVStack {
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
                        ForEach(Array(zip(guilds.indices, guilds)), id: \.1.id) { offset, guild in
                            ZStack(alignment: .bottomTrailing) {
                                Button(action: {
                                    withAnimation {
                                        DispatchQueue.main.async {
                                            selectedServer = offset
                                        }
                                    }
                                }) { [weak guild] in
                                    Attachment(iconURL(guild?.id ?? "", guild?.icon ?? ""), size: nil)
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
                    .padding(.vertical)
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
                    }
                } else if selectedServer == 999 {
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
                    GuildView(guild: $guilds[selectedServer ?? 0], selection: $selection)
                }
            })
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("READY"))) { notif in
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
            }
            order()
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

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
                    HStack {
                        List {
                            Text("Messages")
                                .fontWeight(.bold)
                                .font(.title2)
                            Divider()
                            ForEach(privateChannels, id: \.id) { channel in
                                NavigationLink(destination: NavigationLazyView(ChannelView(guildID: "@me", channelID: channel.id, channelName: channel.name ?? channel.recipients?[0].username ?? "Unknown Channel").equatable()), tag: (Int(channel.id) ?? 0), selection: $selection) { [weak channel] in
                                    if let channel = channel {
                                        ServerListViewCell(channel: channel)
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
                        GuildView(guild: $guilds[selectedServer ?? 0]).equatable()
                    }
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
                        
            for guild in guilds {
                let name = "\(guild.id)$\(guild.name)"
                AllEmotes.shared.allEmotes[name] = guild.emojis
                for channel in guild.channels ?? [] {
                    channel.guild_id = guild.id
                }
            }
            if sortByMostRecent {
                
                guilds.sort { ($0.channels ?? []).sorted(by: {$0.last_message_id ?? "" > $1.last_message_id ?? ""})[0].last_message_id ?? "" > ($1.channels ?? []).sorted(by: {$0.last_message_id ?? "" > $1.last_message_id ?? ""})[0].last_message_id ?? "" }
                
            } else {
                guildOrder = full?.user_settings?.guild_positions ?? []
                var guildTemp = [Guild]()
                for item in guildOrder {
                    if let first = fastIndexGuild(item, array: guilds) {
                        guildTemp.append(guilds[first])
                    }
                }
                self.guilds = guildTemp
            }
            concurrentQueue.async {
                roleColors = (RoleManager.shared?.arrangeRoleColors(guilds: guilds))!
            }
            order()
            DispatchQueue.main.async {
                selectedServer = 0
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

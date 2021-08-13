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

struct ServerListView: View {
    @Binding var guilds: [[String:Any]]
    @Binding var full: [String:Any]
    @State var selection: Int? = nil
    @State var selectedServer: Int? = nil
    @State var privateChannels: [[String:Any]] = []
    @State var guildOrder: [String] = []
    @State var guildIcons: [String:NSImage] = [:]
    @State var pings: [(String, String)] = []
    @State var stuffSelection: Int? = nil
    var body: some View {
        NavigationView {
            HStack(spacing: 0, content: {
                List {
                    if (selectedServer ?? 0) == 999 {
                        ZStack {
                            Color.primary.colorInvert()
                            Image(systemName: "bubble.left.fill")
                        }
                        .frame(width: 45, height: 45)
                        .cornerRadius(15)
                        .onTapGesture(count: 1, perform: {
                            DispatchQueue.main.async {
                                selectedServer = 999
                            }
                        })
                    } else {
                        ZStack {
                            Color.primary.colorInvert()
                            Image(systemName: "bubble.left.fill")
                        }
                        .frame(width: 45, height: 45)
                        .cornerRadius(23.5)
                        .onTapGesture(count: 1, perform: {
                            DispatchQueue.main.async {
                                selectedServer = 999
                            }
                        })
                    }
                    Divider()
                    // MARK: Guild icon UI
                    ForEach(0..<guilds.count, id: \.self) { index in
                        ZStack(alignment: .bottomTrailing) {
                            Attachment("https://cdn.discordapp.com/icons/\(guilds[index]["id"] as? String ?? "")/\(guilds[index]["icon"] as? String ?? "").png?size=128")
                                .frame(width: 45, height: 45)
                                .cornerRadius(((selectedServer ?? 0) == index) ? 15.0 : 23.5)
                                .onTapGesture(count: 1, perform: {
                                    withAnimation {
                                        DispatchQueue.main.async {
                                            selectedServer = index
                                            if let index = (pings.map { $0.0 }).firstIndex(of: guilds[index]["id"] as? String ?? "") {
                                                pings.remove(at: index)
                                            }
                                        }
                                    }
                                })
                            if (pings.map { $0.0 }).contains(guilds[index]["id"] as? String ?? "") {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.red)
                                        .frame(width: 15, height: 15)
                                    Text(String(describing: pings.filter { $0.0 == guilds[index]["id"] as? String ?? ""}.count))
                                        .foregroundColor(Color.white)
                                        .fontWeight(.semibold)
                                }

                            } else {
                            }
                        }

                    }
                    Divider()
                    #if DEBUG
                    if (selectedServer ?? 0) == 1111 {
                        ZStack {
                            Color.primary.colorInvert()
                            Image(systemName: "ant")
                        }
                        .frame(width: 45, height: 45)
                        .cornerRadius(15)
                        .onTapGesture(count: 1, perform: {
                            DispatchQueue.main.async {
                                selectedServer = 1111
                            }
                        })
                    } else {
                        ZStack {
                            Color.primary.colorInvert()
                            Image(systemName: "ant")
                        }
                        .frame(width: 45, height: 45)
                        .cornerRadius(23.5)
                        .onTapGesture(count: 1, perform: {
                            DispatchQueue.main.async {
                                selectedServer = 1111
                            }
                        })
                    }
                    #endif
                    ZStack(alignment: .bottomTrailing) {
                        Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 45, height: 45)
                        Circle()
                            .foregroundColor(Color.green.opacity(0.75))
                            .frame(width: 10, height: 10)
                    }
                    .onTapGesture(count: 1, perform: {
                        DispatchQueue.main.async {
                            selectedServer = 9999
                        }
                    })
                }
                .frame(width: 80)
                .listStyle(SidebarListStyle())
                .buttonStyle(BorderlessButtonStyle())
                Divider()
                if selectedServer == nil {
                    VStack {
                        Text("Connecting...")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear(perform: {
                            DispatchQueue.main.async {
                                NetworkHandling.shared?.request(url: "https://discordapp.com/api/users/@me/channels", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { success, array in
                                    if success {
                                        guard array != nil else {
                                            return
                                        }
                                        privateChannels = array!.sorted { $0["last_message_id"] as? String ?? "" > $1["last_message_id"] as? String ?? "" }
                                        Notifications.shared.privateChannels = array!.map { $0["id"] as! String }
                                    }
                                }
                            }
                        })
                    }

                } else if selectedServer == 9999 {
                    List {
                        NavigationLink(destination: ProfileView(), tag: 0, selection: self.$stuffSelection) {
                            Text("Profile")
                        }
                        NavigationLink(destination: SettingsViewRedesign(), tag: 1, selection: self.$stuffSelection) {
                            Text("Settings")
                        }
                    }
                } else if selectedServer == 999 {
                    HStack {
                        List {
                            Text("Messages")
                                .fontWeight(.bold)
                                .font(.title2) 
                            Divider()
                            ForEach(0..<privateChannels.count, id: \.self) { index in
                                NavigationLink(destination: GuildView(guildID: Binding.constant("@me"), channelID: Binding.constant(privateChannels[index]["id"] as! String), channelName: Binding.constant(((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") }).map{ "\($0)" }.joined(separator: ", ") ), members: Dictionary(uniqueKeysWithValues: zip(((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["id"] as? String ?? "") }), ((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") })))).equatable(), tag: (Int(privateChannels[index]["id"] as! String) ?? 0), selection: self.$selection) {
                                    HStack {
                                        if let recipients = privateChannels[index]["recipients"] as? [[String:Any]] {
                                            if recipients.count != 1 {
                                                Attachment("https://cdn.discordapp.com/channel-icons/\(privateChannels[index]["id"] as? String ?? "")/\(privateChannels[index]["icon"] as? String ?? "").png")
                                                    .clipShape(Circle())
                                                    .frame(width: 25, height: 25)
                                                Text(privateChannels[index]["name"] as? String ?? "")
                                                Spacer()
                                                Button(action: {
                                                    showWindow(guildID: "@me", channelID: privateChannels[index]["id"] as! String, channelName: ((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") }).map{ "\($0)" }.joined(separator: ", ") )
                                                }) {
                                                    Image(systemName: "arrow.up.right.circle")
                                                }
                                            } else {
                                                Attachment("https://cdn.discordapp.com/avatars/\(recipients[0]["id"] as? String ?? "")/\(recipients[0]["avatar"] as? String ?? "").png")
                                                    .clipShape(Circle())
                                                    .frame(width: 25, height: 25)
                                                Text(recipients[0]["username"] as? String ?? "")
                                                Spacer()
                                                Button(action: {
                                                    showWindow(guildID: "@me", channelID: privateChannels[index]["id"] as! String, channelName: ((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") }).map{ "\($0)" }.joined(separator: ", ") )
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
                } else if (selectedServer ?? 0) == 1111 {
                    #if DEBUG
                    List(logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.body, design: .monospaced))
                    }
                    .background(Color.primary.colorInvert())
                    #endif
                } else {
                    if guilds.isEmpty == false {
                        List {
                            if let channels = guilds[selectedServer ?? 0]["channels"] as? [[String:Any]] {
                                ForEach(Array(channels).enumerated().reversed().reversed(), id: \.offset) { offset, section in
                                    if section["type"] as! Int == 4 {
                                        Section(header: Text(section["name"] as! String)) {
                                            ForEach(Array(channels).enumerated().reversed().reversed(), id: \.offset) { offset, channel in
                                                if channel["type"] as! Int != 4 {
                                                    if channel["parent_id"] as? String ?? "no" == section["id"] as! String {
                                                        NavigationLink(destination: GuildView(guildID: Binding.constant((guilds[selectedServer ?? 0]["id"] as? String ?? "")), channelID: Binding.constant(channel["id"] as! String), channelName: Binding.constant(channel["name"] as! String)).equatable(), tag: (Int(channel["id"] as! String) ?? 0), selection: self.$selection) {
                                                            HStack {
                                                                switch channel["type"] as! Int {
                                                                case 0:
                                                                    Image(systemName: "number") // normal channel
                                                                case 2:
                                                                    Image(systemName: "speaker.wave.2.fill") // voice chat
                                                                case 5:
                                                                    Image(systemName: "megaphone.fill") // announcement channel
                                                                case 13:
                                                                    Image(systemName: "person.2.fill") // stages
                                                                default:
                                                                    Image(systemName: "camera.metering.unknown") // unknown
                                                                }
                                                                Text(channel["name"] as! String)
                                                                Spacer()
                                                                Button(action: {
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
                    }
                }
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("READY"))) { notif in
            if sortByMostRecent {
                guilds.sort { ($0["channels"] as? [[String:Any]] ?? []).sorted(by: {$0["last_message_id"] as? String ?? "" > $1["last_message_id"] as? String ?? ""})[0]["last_message_id"] as? String ?? "" > ($1["channels"] as? [[String:Any]] ?? []).sorted(by: {$0["last_message_id"] as? String ?? "" > $1["last_message_id"] as? String ?? ""})[0]["last_message_id"] as? String ?? "" }
            } else {
                guildOrder = (full["user_settings"] as? [String:Any] ?? [:])["guild_positions"] as? [String] ?? []

                full = [:]
                let guildIDs = guilds.map { $0["id"] } as! [String]
                var guildTemp: [[String:Any]] = []
                for item in guildOrder {
                    if let first = guildIDs.firstIndex(of: item) {
                        guildTemp.append(guilds[first])
                    }
                }
                guilds = guildTemp
            }
            selectedServer = 0
            print("[Accord] cleaned up")
            roleColors = (RoleManager.shared?.arrangeRoleColors(guilds: guilds))!
            print(roleColors)
            for i in 0..<guilds.count {
                guilds[i]["members"] = nil
                guilds[i]["threads"] = nil
                print("[Accord] \(guilds[i]["id"] as! String)$\(guilds[i]["name"] as! String)")
                AllEmotes.shared.allEmotes["\(guilds[i]["id"] as! String)$\(guilds[i]["name"] as! String)"] = try! JSONDecoder().decode([DiscordEmote].self, from: (try! JSONSerialization.data(withJSONObject: (guilds[i]["emojis"] as! [[String:Any]]), options: [])))
                print(AllEmotes.shared.allEmotes)
                (guilds[i]["channels"]) = (guilds[i]["channels"] as! [[String:Any]]).sorted(by: { $1["position"] as! Int > $0["position"] as! Int }) as Any
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SETUP_DONE"), object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Notification"))) { notif in
            pings.append((notif.userInfo as! [String:Any])["info"] as! (String, String))
        }

        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

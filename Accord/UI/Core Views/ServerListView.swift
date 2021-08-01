//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import SwiftUI

public var roleColors: [String:Int] = [:]

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
                        if (selectedServer ?? 0) == index {
                            Image(nsImage: guildIcons[guilds[index]["id"] as? String ?? ""] ?? NSImage()).resizable()
                                .frame(width: 45, height: 45)
                                .cornerRadius(15)
                                .scaledToFit()
                                .onTapGesture(count: 1, perform: {
                                    withAnimation {
                                        DispatchQueue.main.async {
                                            selectedServer = index
                                        }
                                    }
                                })
                        } else {
                            Image(nsImage: guildIcons[guilds[index]["id"] as? String ?? ""] ?? NSImage()).resizable()
                                .scaledToFit()
                                .frame(width: 45, height: 45)
                                .cornerRadius(23.5)
                                .onTapGesture(count: 1, perform: {
                                    withAnimation {
                                        DispatchQueue.main.async {
                                            selectedServer = index
                                        }
                                    }
                                })
                        }

                    }
                    Divider()
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
                                    }
                                }
                            }
                        })
                    }

                } else if selectedServer == 9999 {
                    ProfileView()
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
                    }
                } else {
                    if guilds.isEmpty == false {
                        List {
                            if let sectionArray = Array(GuildManager.shared.channelCount(array: guilds[selectedServer ?? 0]["channels"] as? [[String:Any]] ?? [], index: 0).keys).sorted() {
                                ForEach(sectionArray, id: \.self) { key in
                                    if let channels = GuildManager.shared.channelCount(array: guilds[selectedServer ?? 0]["channels"] as? [[String:Any]] ?? [], index: 0) {
                                        if let sectionName = ((guilds[selectedServer ?? 0]["channels"] as? [[String:Any]] ?? []).map { $0["name"]  as! String })[((guilds[selectedServer ?? 0]["channels"] as? [[String:Any]] ?? []).map { $0["id"] as! String }).firstIndex(of: key) as? Int ?? 0] {
                                            Section(header: Text(sectionName)) {
                                                if let channel = channels[key] {
                                                    ForEach(0..<channel.count, id: \.self) { offset in
                                                        if let channelName = Array((GuildManager.shared.getGuild(guildid: (guilds[selectedServer ?? 0]["id"] as? String ?? ""), array: guilds, type: .name) as? [String] ?? []))[(GuildManager.shared.getGuild(guildid: (guilds[selectedServer ?? 0]["id"] as? String ?? ""), array: guilds, type: .id) as? [String] ?? []).firstIndex(of: channel[offset])!] {
                                                            NavigationLink(destination: GuildView(guildID: Binding.constant((guilds[selectedServer ?? 0]["id"] as? String ?? "")), channelID: Binding.constant(channel[offset]), channelName: Binding.constant(channelName)).equatable(), tag: (Int(channel[offset]) ?? 0), selection: self.$selection) {
                                                                HStack {
                                                                    Image(systemName: "number")
                                                                    Text(channelName)
                                                                    Spacer()
                                                                    Button(action: {
                                                                        showWindow(guildID: (guilds[selectedServer ?? 0]["id"] as? String ?? ""), channelID: channel[offset], channelName: channelName)
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
                        }
                    }
                }
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("READY"))) { notif in
            ImageHandling.shared?.getServerIcons(array: guilds) { success, icons in
                if success {
                    guildIcons = icons
                    print(guildIcons, "ICONS")
                }
            }
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
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SETUP_DONE"), object: nil)
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}



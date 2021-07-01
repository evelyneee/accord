//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import SwiftUI

struct ServerListView: View {
    @Binding var clubs: [[String:Any]]
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
                    ZStack {
                        Color.primary.colorInvert()
                        Image(systemName: "bubble.left.fill")
                    }
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .onTapGesture(count: 1, perform: {
                        selectedServer = 999
                    })
                    Divider()
                    ForEach(0..<clubs.count, id: \.self) { index in
                        Image(nsImage: guildIcons[clubs[index]["id"] as? String ?? ""] ?? NSImage()).resizable()
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                            .scaledToFit()
                            .onTapGesture(count: 1, perform: {
                                selectedServer = index
                                
                            })

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
                        selectedServer = 9999
                    })
                }
                .frame(width: 80)
                .buttonStyle(PlainButtonStyle())
                Divider()
                if selectedServer == nil {
                    VStack {
                        Text("Connecting...")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear(perform: {
                            DispatchQueue.main.async {
                                NetworkHandling.shared?.request(url: "https://discordapp.com/api/users/@me/channels", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
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
                                NavigationLink(destination: GuildView(clubID: Binding.constant("@me"), channelID: Binding.constant(privateChannels[index]["id"] as! String), channelName: Binding.constant(((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") }).map{ "\($0)" }.joined(separator: ", ") )), tag: (Int(privateChannels[index]["id"] as! String) ?? 0), selection: self.$selection) {
                                    HStack {
                                        if let recipients = privateChannels[index]["recipients"] as? [[String:Any]] {
                                            if recipients.count != 1 {
                                                Attachment("https://cdn.discordapp.com/channel-icons/\(privateChannels[index]["id"] as? String ?? "")/\(privateChannels[index]["icon"] as? String ?? "").png")
                                                    .clipShape(Circle())
                                                    .frame(width: 25, height: 25)
                                                Text(privateChannels[index]["name"] as? String ?? "")
                                                Spacer()
                                                Button(action: {
                                                    showWindow(clubID: "@me", channelID: privateChannels[index]["id"] as! String, channelName: ((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") }).map{ "\($0)" }.joined(separator: ", ") )
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
                                                    showWindow(clubID: "@me", channelID: privateChannels[index]["id"] as! String, channelName: ((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") }).map{ "\($0)" }.joined(separator: ", ") )
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
                    if clubs.isEmpty == false {
                        List {
                            if let sectionArray = Array(GuildManager.shared.channelCount(array: clubs[selectedServer ?? 0]["channels"] as? [[String:Any]] ?? [], index: 0).keys).sorted() {
                                ForEach(sectionArray, id: \.self) { key in
                                    if let channels = GuildManager.shared.channelCount(array: clubs[selectedServer ?? 0]["channels"] as? [[String:Any]] ?? [], index: 0) {
                                        if let sectionName = ((clubs[selectedServer ?? 0]["channels"] as? [[String:Any]] ?? []).map { $0["name"]  as! String })[((clubs[selectedServer ?? 0]["channels"] as? [[String:Any]] ?? []).map { $0["id"] as! String }).firstIndex(of: key) as? Int ?? 0] {
                                            Section(header: Text(sectionName)) {
                                                if let channel = channels[key] {
                                                    ForEach(0..<channel.count, id: \.self) { offset in
                                                        if let channelName = Array((GuildManager.shared.getGuild(clubid: (clubs[selectedServer ?? 0]["id"] as? String ?? ""), array: clubs, type: .name) as? [String] ?? []))[(GuildManager.shared.getGuild(clubid: (clubs[selectedServer ?? 0]["id"] as? String ?? ""), array: clubs, type: .id) as? [String] ?? []).firstIndex(of: channel[offset])!] {
                                                            NavigationLink(destination: GuildView(clubID: Binding.constant((clubs[selectedServer ?? 0]["id"] as? String ?? "")), channelID: Binding.constant(channel[offset]), channelName: Binding.constant(channelName)), tag: (Int(channel[offset]) ?? 0), selection: self.$selection) {
                                                                HStack {
                                                                    Image(systemName: "number")
                                                                    Text(channelName)
                                                                    Spacer()
                                                                    Button(action: {
                                                                        showWindow(clubID: (clubs[selectedServer ?? 0]["id"] as? String ?? ""), channelID: channel[offset], channelName: channelName)
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
            ImageHandling.shared?.getServerIcons(array: clubs) { success, icons in
                if success {
                    guildIcons = icons
                    print(guildIcons, "ICONS")
                }
            }
            guildOrder = (full["user_settings"] as? [String:Any] ?? [:])["guild_positions"] as? [String] ?? []
            for i in 0..<clubs.count {
                clubs[i]["emojis"] = nil
                clubs[i]["members"] = nil
                clubs[i]["threads"] = nil
            }
            full = [:]
            let clubIDs = clubs.map { $0["id"] } as! [String]
            var clubTemp: [[String:Any]] = []
            for (index, item) in guildOrder.enumerated() {
                if let first = clubIDs.firstIndex(of: item) {
                    let element = clubs[first]
                    print(element)
                    clubTemp.insert(element, at: index)
                }
            }
            clubs = clubTemp 
            selectedServer = 0
            print("cleaned up")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SETUP_DONE"), object: nil)
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}


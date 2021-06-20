//
//  ServerListView.swift
//  Discord
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
    var body: some View {
        NavigationView {
            HStack(spacing: 0, content: {
                List {
                    ZStack {
                        Color.primary.colorInvert()
                        Image(systemName: "bubble.left.fill")
                    }
                    .onTapGesture(count: 1, perform: {
                        selectedServer = 999
                    })
                    ForEach(0..<clubs.count, id: \.self) { index in
                        ZStack {
                            Color.gray
                            ImageWithURL("https://cdn.discordapp.com/icons/\(clubs[index]["id"] as? String ?? "")/\(clubs[index]["icon"] as? String ?? "")")
                        }
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                        .onTapGesture(count: 1, perform: {
                            selectedServer = index
                            print(clubs[index]["icon"] as? String ?? "")
                        })
                    }
                    NavigationLink(destination: ProfileView()) {
                        ZStack {
                            Color.primary.colorInvert()
                            Image(systemName: "person.crop.circle")
                        }
                    }
                }
                .frame(width: 80)
                .buttonStyle(PlainButtonStyle())
                if selectedServer == nil {
                    VStack {
                        Text("Connecting...")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear(perform: {
                            DispatchQueue.main.async {
                                net.request(url: "https://discordapp.com/api/users/@me/channels", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                                    privateChannels = array ?? []
                                }
                            }
                        })
                    }

                } else if selectedServer == 999 {
                    HStack {
                        List(0..<privateChannels.count, id: \.self) { index in
                            NavigationLink(destination: ClubView(channelID: Binding.constant(privateChannels[index]["id"] as! String), channelName: Binding.constant(((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") }).map{ "\($0)" }.joined(separator: ", ") as! String)), tag: (Int(privateChannels[index]["id"] as! String) ?? 0), selection: self.$selection) {
                                HStack {
                                    Text(((privateChannels[index]["recipients"] as? [[String:Any]] ?? []).map { ($0["username"] as? String ?? "") }).map{ "\($0)" }.joined(separator: ", "))
                                        .fontWeight(.medium)
                                        .font(.title3)
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                } else {
                     List(Array((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[selectedServer ?? 0], type: .id) as? [String] ?? []).enumerated()), id: \.offset) { offset, channel in
                        if let channelid = channel {
                            if let channelName = Array((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[selectedServer ?? 0], type: .name) as? [String] ?? []))[safe: offset] {
                                NavigationLink(destination: ClubView(channelID: Binding.constant(channelid), channelName: Binding.constant(channelName)), tag: (Int(channelid) ?? 0), selection: self.$selection) {
                                    HStack {
                                        Text("\(channelName)")
                                            .fontWeight(.medium)
                                            .font(.title3)
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("READY"))) { notif in
            guildOrder = (full["user_settings"] as? [String:Any] ?? [:])["guild_positions"] as? [String] ?? []
            let clubIDs = clubs.map { $0["id"] } as! [String]
            var clubTemp: [[String:Any]] = []
            for (index, item) in guildOrder.enumerated() {
                let element = clubs[clubIDs.firstIndex(of: item)!]
                clubTemp.insert(element, at: index)
            }
            print(clubs)
            clubs = clubTemp
            selectedServer = 0
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

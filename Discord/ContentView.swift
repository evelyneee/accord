//
//  ContentView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-24.
//

import SwiftUI

struct ContentView: View {
    @State public var selection: Int?
    @State var clubs: [[String:Any]] = []
    @State var channels: [Any] = []
    @State var status: statusIndicators?
    @State var modalIsPresented: Bool = false {
        didSet {
            DispatchQueue.main.async {
                NetworkHandling.shared.request(url: "\(rootURL)/users/@me/\(clubsorguilds)", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                    if success == true {
                        clubs = array ?? []
                    }
                }
            }
        }
    }
    var body: some View {
        NavigationView {
            List {
                Spacer()
                NavigationLink(destination: ClubView(channelID: Binding.constant("831692717397770272"), channelName: Binding.constant("that one dm"))) {
                    HStack {
                        Text("that one dm")
                            .fontWeight(.medium)
                            .font(.title3)
                    }
                }
                NavigationLink(destination: ClubView(channelID: Binding.constant("756865973394472960"), channelName: Binding.constant("cutie"))) {
                    HStack {
                        Text("cutie")
                            .fontWeight(.medium)
                            .font(.title3)
                    }
                }
                Divider()
                if token != "" {
                    ForEach(0..<clubs.count, id: \.self) { index in
                        Section(header: Text((parser.getArray(forKey: "name", messageDictionary: clubs)[safe: index]) as? String ?? "")) {
                            ForEach(Array((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[index], type: .id) as? [String] ?? []).enumerated()), id: \.offset) { offset, channel in
                                if let channelid = channel {
                                    if let channelName = Array((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[index], type: .name) as? [String] ?? []))[safe: offset] {
                                        NavigationLink(destination: ClubView(channelID: Binding.constant(channelid), channelName: Binding.constant(channelName)), tag: (Int(channelid) ?? 0), selection: self.$selection) {
                                            HStack {
                                                Text("\(channelName)")
                                                    .fontWeight(.medium)
                                                    .font(.title3)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Divider()
                NavigationLink(destination: HomeView()) {
                    HStack {
                        Image(systemName: "house.fill")
                            .imageScale(.small)
                        Text("Home")
                            .fontWeight(.medium)
                            .font(.title3)
                    }
                }
                NavigationLink(destination: ProfileView()) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .imageScale(.small)
                        Text("Profile")
                            .fontWeight(.medium)
                            .font(.title3)
                    }
                }
                Spacer()
                HStack {
                    ZStack(alignment: .bottomTrailing) {
                        Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 30, height: 30)
                        Circle()
                            .foregroundColor(Color.green.opacity(0.75))
                            .frame(width: 10, height: 10)
                    }

                    Text("\(username)#\(discriminator)")
                    Spacer()
                }
            }
            .frame(minWidth: 160, maxWidth: 350)
            .listStyle(SidebarListStyle())
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .sheet(isPresented: $modalIsPresented) {
            LoginView()
                .onDisappear(perform: {
                    DispatchQueue.main.async {
                        NetworkHandling.shared.request(url: "\(rootURL)/users/@me/\(clubsorguilds)", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                            if success == true {
                                clubs = array ?? []
                            }
                        }
                    }
                })
                .frame(width: 450, height: 200)

        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("logged_in"))) { obj in
            DispatchQueue.main.async {
                DispatchQueue.main.async {
                    WebSocketHandler.shared.newMessage(opcode: 2, item: "guilds") { success, array in
                         if !(array?.isEmpty ?? true) {
                             clubs = array ?? []
                         }
                    }
                    net.requestData(url: "\(rootURL)/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                        if (completion) {
                            user_id = ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? ""
                            net.requestData(url: "https://cdn.discordapp.com/avatars/\(ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar", data: data)[safe: 0]  as? String ?? "").png?size=80", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                            username = ProfileManager.shared.getSelfProfile(key: "username", data: data)[safe: 0]  as? String ?? ""
                            discriminator = ProfileManager.shared.getSelfProfile(key: "discriminator", data: data)[safe: 0]  as? String ?? ""
                        }
                    }
                }
            }
        }
        .onAppear {
            if (token != "") {
                DispatchQueue.main.async {
                    WebSocketHandler.shared.newMessage(opcode: 2, item: "guilds") { success, array in
                         if !(array?.isEmpty ?? true) {
                             clubs = array ?? []
                         }
                    }
                    net.requestData(url: "\(rootURL)/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                        if (completion) {
                            user_id = ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? ""
                            net.requestData(url: "https://cdn.discordapp.com/avatars/\(ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar", data: data)[safe: 0]  as? String ?? "").png?size=80", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                            username = ProfileManager.shared.getSelfProfile(key: "username", data: data)[safe: 0]  as? String ?? ""
                            discriminator = ProfileManager.shared.getSelfProfile(key: "discriminator", data: data)[safe: 0]  as? String ?? ""
                        }
                    }
                    
                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

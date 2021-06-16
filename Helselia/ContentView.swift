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
                NetworkHandling.shared.request(url: "https://constanze.live/api/v1/users/@me/clubs", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
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
                if !(clubs.isEmpty) {
                    ForEach(0..<clubs.count, id: \.self) { index in
                        Section(header: Text((parser.getArray(forKey: "name", messageDictionary: clubs)[index]) as? String ?? "")) {
                            ForEach(Array((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[index], type: .id) as? [String] ?? []).enumerated()), id: \.offset) { offset, channel in
                                if let channelid = channel {
                                    if let channelName = Array((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[index], type: .name) as? [String] ?? []))[offset] {
                                        NavigationLink(destination: ClubView(channelID: Binding.constant(channelid), channelName: Binding.constant(channelName)), tag: (Int(channelid) ?? 0), selection: self.$selection) {
                                            HStack {
                                                Image(systemName: "captions.bubble.fill")
                                                    .imageScale(.small)
                                                Text(channelName)
                                                    .fontWeight(.semibold)
                                                    .font(.title2)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Divider()
                NavigationLink(destination: MyIssues()) {
                    HStack {
                        Image(systemName: "ant.fill")
                            .imageScale(.small)
                        Text("Issues(\(issueContainer.count))")
                            .fontWeight(.semibold)
                            .font(.title2)
                    }
                }
                Divider()
                NavigationLink(destination: HomeView()) {
                    HStack {
                        Image(systemName: "house.fill")
                            .imageScale(.small)
                        Text("Home")
                            .fontWeight(.semibold)
                            .font(.title2)
                    }
                }
                NavigationLink(destination: ProfileView()) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .imageScale(.small)
                        Text("Profile")
                            .fontWeight(.semibold)
                            .font(.title2)
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
                        NetworkHandling.shared.request(url: "https://constanze.live/api/v1/users/@me/clubs", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                            if success == true {
                                clubs = array ?? []
                            }
                        }
                    }
                })
                .frame(width: 450, height: 200)

        }
        .onAppear {
            if (token != "") {
                DispatchQueue.main.async {
                    net.requestData(url: "https://constanze.live/api/v1/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                        if (completion) {
                            user_id = ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? ""
                            net.requestData(url: "https://cdn.constanze.live/avatars/\(ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar", data: data)[safe: 0]  as? String ?? "").png", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                            username = ProfileManager.shared.getSelfProfile(key: "username", data: data)[safe: 0]  as? String ?? ""
                            discriminator = ProfileManager.shared.getSelfProfile(key: "discriminator", data: data)[safe: 0]  as? String ?? ""
                        }
                    }
                    
                }
                WebSocketHandler.shared.newMessage(opcode: 2, item: "clubs")  { success, array in
                    if !(array?.isEmpty ?? true) {
                        clubs = array ?? []
                    }
                }
                print(clubs)
            } else {
                modalIsPresented = true
            }
        }
    }
}

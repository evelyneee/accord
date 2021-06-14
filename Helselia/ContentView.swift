//
//  ContentView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-24.
//
// (ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs)), type: .id) as? [String] ?? [])

import SwiftUI

struct ContentView: View {
    @State public var selection: Int?
    @State var clubs: [[String:Any]] = []
    @State var channels: [Any] = []
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
                                if let channelid = channel as? String {
                                    if let channelName = Array((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[index], type: .name) as? [String] ?? []))[offset] as? String {
                                        NavigationLink(destination: ClubView(channelID: Binding.constant(channelid), channelName:     Binding.constant(channelName)), tag: (Int(channelid) ?? 0), selection: self.$selection) {
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
                    NetworkHandling.shared.request(url: "https://constanze.live/api/v1/users/@me/clubs", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                        if success == true {
                            clubs = array ?? []
                        }
                    }
                    net.requestData(url: "https://constanze.live/api/v1/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                        if (completion) {
                            user_id = ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? ""
                            _ = net.requestData(url: "https://cdn.constanze.live/avatars/\(ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar", data: data)[safe: 0]  as? String ?? "").png", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                            username = ProfileManager.shared.getSelfProfile(key: "username", data: data)[safe: 0]  as? String ?? ""
                        }
                    }
                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

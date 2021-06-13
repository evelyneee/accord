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
    
    var body: some View {
        NavigationView {
            List {
                Spacer()
                if (token != "") {
                    ForEach(0..<clubs.count, id: \.self) { index in
                        Section(header: Text((parser.getArray(forKey: "name", messageDictionary: clubs)[index]) as? String ?? "")) {
                            ForEach(Array((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[index], type: .id) as? [String] ?? []).enumerated()), id: \.offset) { offset, channel in
                                if let channelid = channel as? String {
                                    NavigationLink(destination: ClubView(channelID: Binding.constant(channelid)), tag: (Int(channelid) ?? 0), selection: self.$selection) {
                                        HStack {
                                            Image(systemName: "captions.bubble.fill")
                                                .imageScale(.small)
                                            Text((ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs) as? [String] ?? [])[index], type: .name) as? [String] ?? [])[offset])
                                                .fontWeight(.semibold)
                                                .font(.title2)
                                        }
                                    }
                                    .onAppear {
                                        print(channel)
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
        .onAppear {
            print(token)
            if (token != "") {
                DispatchQueue.main.async {
                    NetworkHandling.shared.request(url: "https://constanze.live/api/v1/users/@me/clubs", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                        if success == true {
                            clubs = array ?? []
                        }
                    }
                }
                print(clubs)
            }
        }
        .onReceiveNotifs(Notification.Name(rawValue: "logged_in")) { _ in
            print("logged in")
            DispatchQueue.main.async {
                NetworkHandling.shared.request(url: "https://constanze.live/api/v1/users/@me/clubs", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                    if success == true {
                        print(clubs)
                        clubs = array ?? []
                    }
                }
            }
        }
    }
}

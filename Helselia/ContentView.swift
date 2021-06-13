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
        .sheet(isPresented: $modalIsPresented) {
            LoginView()
                .onDisappear(perform: {
                    print("there")
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
            print(token)
            if (token != "") {
                DispatchQueue.main.async {
                    NetworkHandling.shared.request(url: "https://constanze.live/api/v1/users/@me/clubs", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                        if success == true {
                            clubs = array ?? []
                        }
                    }
                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

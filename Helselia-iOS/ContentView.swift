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
    var body: some View {
        NavigationView {
            List {
                Spacer()
                if (token != "") {
                    ForEach(0..<clubs.count, id: \.self) { index in
                        NavigationLink(destination: ClubView(clubID: Binding.constant(parser.getArray(forKey: "id", messageDictionary: clubs)[index] as! String), channelID: Binding.constant(ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs)[index] as! String), type: .id)[0] as! String)), tag: (index + 1), selection: self.$selection) {
                            HStack {
                                Image(systemName: "captions.bubble.fill")
                                    .imageScale(.small)
                                Text(parser.getArray(forKey: "name", messageDictionary: clubs)[index] as! String)
                                    .fontWeight(.semibold)
                                    .font(.title2)
                            }
                            .onAppear {
                                let club = ClubManager.shared.getClub(clubid: (parser.getArray(forKey: "id", messageDictionary: clubs)[index] as! String), type: .id)
                                print(club[0], parser.getArray(forKey: "name", messageDictionary: clubs)[index] as! String)
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
            self.selection = 0
            print(token)
            if (token != "") {
                NetworkHandling.shared.request(url: "https://constanze.live/api/v1/users/@me/clubs", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                    if success == true {
                        clubs = array ?? []
                    }
                }
                print(clubs)
            }
        }
    }
}

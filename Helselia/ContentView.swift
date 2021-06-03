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
    var body: some View {
        NavigationView {
            List {
                Spacer()
                ForEach(0..<clubs.count, id: \.self) { index in
                    NavigationLink(destination: ClubView(clubID: Binding.constant(parser.getArray(forKey: "id", messageDictionary: clubs)[index] as! String), channelID: Binding.constant("177711870931767299")), tag: (index + 1), selection: self.$selection) {
                        HStack {
                            Image(systemName: "captions.bubble.fill")
                                .imageScale(.small)
                            Text(parser.getArray(forKey: "name", messageDictionary: clubs)[index] as! String)
                                .fontWeight(.semibold)
                                .font(.title2)
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
            clubs = net.request(url: "https://constanze.live/api/v1/users/@me/clubs", token: token, Cookie: "__cfduid=d9ee4b332e29b7a9b1e0befca2ac718461620217863", json: false, type: .GET, bodyObject: [:])
            print(clubs)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  ContentView.swift
//  Helselia
//
//  Created by althio on 2020-11-24.
//

import SwiftUI

struct ContentView: View {
    @State public var selection: Int?
    var body: some View {
        NavigationView {
            List {
                Spacer()
                NavigationLink(destination: ClubView(), tag: 0, selection: self.$selection) {
                    HStack {
                        Image(systemName: "captions.bubble.fill")
                            .imageScale(.small)
                        Text("Swift")
                            .fontWeight(.semibold)
                            .font(.title2)
                    }
                }
                NavigationLink(destination: ClubView()) {
                    HStack {
                        Image(systemName: "captions.bubble.fill")
                            .imageScale(.small)
                        Text("Objective-C")
                            .fontWeight(.semibold)
                            .font(.title2)
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
                ForEach(0..<issueContainer.count, id: \.self) { issueIdentifier in
                    NavigationLink(
                        destination: ClubView(),
                        label: {
                            Image(systemName: "questionmark.circle.fill")
                            Text(issueContainer[issueIdentifier])
                                .font(.title3)
                                .fontWeight(.semibold)
                        })
                        .padding(.leading, 5)
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

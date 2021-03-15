//
//  ContentView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-24.
//

import SwiftUI

struct ContentView: View {
    @State public var selection: Int?
    enum displaytypes {
        case inline
        case large
    }
    var display: NavigationBarItem.TitleDisplayMode = .large
    var body: some View {
        VStack {
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
                .navigationTitle("Helselia")
                .navigationBarHidden(false)
                .navigationBarTitleDisplayMode(display)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

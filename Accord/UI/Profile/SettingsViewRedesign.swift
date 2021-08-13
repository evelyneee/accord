//
//  SettingsViewRedesign.swift
//  Accord
//
//  Created by evewyn on 2021-07-14.
//

import Foundation
import SwiftUI

struct SettingsViewRedesign: View {
    @State var bioText: String = " "
    @State var username: String = "test user"
    @State var profilePictures: Bool = pfpShown
    @State var recent: Bool = sortByMostRecent
    @State var dark: Bool = darkMode
    @State var user: User? = AccordCoreVars.shared.user
    @State var proxyIP: String = ""
    @State var proxyPort: String = ""
    @State var proxyEnable: Bool = proxyEnabled

    var body: some View {
        List {
            LazyVStack(alignment: .leading) {
                Text("Accord Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 20)
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("Email")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(user?.email ?? "No email found")
                        }
                        .padding(.bottom, 10)
                        VStack(alignment: .leading) {
                            Text("Phone number")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("not done yet, placeholder")
                        }
                        .padding(.bottom, 10)
                        Spacer()
                    }
                    .padding()
                    Divider()
                    VStack(alignment: .leading) {
                        Text("Bio")
                            .font(.title3)
                            .fontWeight(.bold)
                        TextEditor(text: $bioText)
                            .frame(height: 75)
                        Text("Username")
                            .font(.title3)
                            .fontWeight(.bold)
                        TextField("username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Spacer()
                    }
                    .frame(idealWidth: 250, idealHeight: 200)
                    .padding()
                    Divider()
                    VStack(alignment: .leading) {
                        Attachment("https://cdn.discordapp.com/avatars/\(user?.id ?? "")/\(user?.avatar ?? "").png?size=256")
                            .clipShape(Circle())
                            .frame(width: 45, height: 45)
                            .shadow(radius: 5)
                        Text(user?.username ?? "Unknown User")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(user?.username ?? "Unknown User")#\(user?.discriminator ?? "0000")")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                        Divider()
                        Text(bioText)
                        Spacer()
                    }
                    .frame(idealWidth: 200, idealHeight: 200)
                    .padding()
                    Spacer()
                }
                .padding(5)
                .background(Color.black.opacity(0.25))
                .cornerRadius(15)
                .padding()
                VStack {
                    HStack(alignment: .top) {
                        Text("Show profile pictures")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $profilePictures) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Text("Sort servers by recent messages")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $recent) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Text("Always dark mode")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $dark) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Text("Log out")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Button(action: {
                            _ = KeychainManager.save(key: "me.evelyn.accord.token", data: String("").data(using: String.Encoding.utf8) ?? Data())
                        }) {
                            Text("log out")
                        }
                        .padding()
                    }

                }
                .padding(5)
                .background(Color.black.opacity(0.25))
                .cornerRadius(15)
                .padding()
                Text("Proxy Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 20)
                VStack {
                    HStack(alignment: .top) {
                        Text("Enable Proxy")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $proxyEnable) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    HStack(alignment: .top) {
                        Text("Proxy IP")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        TextField("IP", text: $proxyIP)
                            .padding()
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(width: 250)
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Text("Proxy Port")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        TextField("Port", text: $proxyPort)
                            .padding()
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(width: 250)
                    }
                }
                .padding(5)
                .background(Color.black.opacity(0.25))
                .cornerRadius(15)
                .padding()
            }
            .onDisappear(perform: {
                darkMode = self.dark
                sortByMostRecent = self.recent
                pfpShown = self.profilePictures
                UserDefaults.standard.set(darkMode, forKey: "darkMode")
                UserDefaults.standard.set(sortByMostRecent, forKey: "sortByMostRecent")
                UserDefaults.standard.set(pfpShown, forKey: "pfpShown")
                UserDefaults.standard.set(self.proxyIP, forKey: "proxyIP")
                UserDefaults.standard.set(self.proxyPort, forKey: "proxyPort")
                UserDefaults.standard.set(self.proxyEnable, forKey: "proxyEnabled")
            })


        }
    }
}

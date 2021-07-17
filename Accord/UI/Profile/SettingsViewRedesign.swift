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
    @Binding var user: User
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
                            Text(user.email ?? "")
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
                    .frame(width: 250, height: 200)
                    .padding()
                    Divider()
                    VStack(alignment: .leading) {
                        Attachment("https://cdn.discordapp.com/avatars/\(user.id)/\(user.avatar ?? "").png?size=256")
                            .clipShape(Circle())
                            .frame(width: 45, height: 45)
                            .shadow(radius: 5)
                        Text(user.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(user.username)#\(user.discriminator)")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                        Divider()
                        Text(bioText)
                        Spacer()
                    }
                    .frame(width: 200, height: 200)
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
                        Toggle(isOn: Binding.constant(true)) {
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
                        Toggle(isOn: Binding.constant(true)) {
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
                        Toggle(isOn: Binding.constant(true)) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                }
                .padding(5)
                .background(Color.black.opacity(0.25))
                .cornerRadius(15)
                .padding()
            }


        }
    }
}

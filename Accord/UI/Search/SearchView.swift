//
//  SearchView.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation
import SwiftUI

struct SearchView: View {
    
    @State var text: String = ""
    @State var results: [Channel] = .init()
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    @State
    var matches: [Channel] = []
    
    @State
    var matchedUsers = [User]()
    
    func match() async -> [Channel] {
                
        let usernames = Storage.users.lazy
            .filter { $0.value.username.lowercased().contains(self.text.dropLast(5).stringLiteral.lowercased()) }
            .map(\.value)
        
        self.matchedUsers = usernames
        
        let matches: [Channel] = appModel.folders.lazy
            .map(\.guilds)
            .joined()
            .map(\.channels)
            .joined()
            .filter { $0.computedName.lowercased().contains(self.text.lowercased()) }
        
        let dmMatches: [Channel] = appModel.privateChannels.lazy
            .filter { $0.computedName.lowercased().contains(text.lowercased()) }
    
        return matches + dmMatches
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                TextField("Jump to channel", text: $text)
                    .font(.title2)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        if let channel = self.matches.first {
                            MentionSender.shared.select(channel: channel)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
            }
            List {
                Spacer().frame(height: 25)
                ForEach(matchedUsers, id: \.id) { user in
                    Button(action: {
                        Request.fetch(Channel.self, url: URL(string: "https://discord.com/api/v9/users/@me/channels"), headers: Headers(
                            token: Globals.token,
                            bodyObject: ["recipients": [user.id]],
                            type: .POST,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/@me",
                            json: true
                        )) {
                            switch $0 {
                            case let .success(channel):
                                print(channel)
                                AppGlobals.newItemPublisher.send((channel, nil))
                                MentionSender.shared.select(channel: channel)
                            case let .failure(error):
                                AccordApp.error(error, text: "Failed to open dm", reconnectOption: false)
                            }
                        }
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        HStack {
                            Attachment(pfpURL(user.id, user.avatar, discriminator: user.discriminator))
                                .equatable()
                                .clipShape(Circle())
                                .frame(width: 23, height: 23)
                            Text(user.username)
                                .foregroundColor(.primary)
                                .font(.system(size: 15))
                            +
                            Text("#" + user.discriminator)
                                .font(.system(size: 15))
                            Spacer()
                        }
                    })
                    .buttonStyle(.borderless)
                }
                ForEach(matches, id: \.id) { channel in
                    Button(action: {
                        MentionSender.shared.select(channel: channel)
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        HStack {
                            if let icon = channel.guild_icon {
                                Attachment(iconURL(channel.guild_id, icon))
                                    .equatable()
                                    .clipShape(Circle())
                                    .frame(width: 23, height: 23)
                            } else if channel.recipients?.count == 1 {
                                Attachment(pfpURL(channel.recipients?[0].id, channel.recipients?[0].avatar, discriminator: channel.recipients?[0].discriminator ?? "0005"))
                                    .equatable()
                                    .clipShape(Circle())
                                    .frame(width: 23, height: 23)
                            } else if let icon = channel.icon {
                                Attachment(cdnURL + "/channel-icons/\(channel.id)/\(icon).png?size=48")
                                    .equatable()
                                    .clipShape(Circle())
                                    .frame(width: 23, height: 23)
                            }
                            Text(channel.computedName)
                                .foregroundColor(Color(NSColor.textColor))
                                .font(.system(size: 15))
                            if let guildName = channel.guild_name {
                                Text(" — \(guildName)")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15))
                            }
                            Spacer()
                        }
                    })
                    .buttonStyle(.plain)
                }
                .onChange(of: self.text, perform: { text in
                    Task.detached {
                        let matches = await self.match()
                        await MainActor.run {
                            self.matches = matches
                        }
                    }
                })
                Spacer()
            }
            .listStyle(.plain)
            .frame(height: 300)
        }
        .frame(width: 400)
        .padding()
        .onExitCommand {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

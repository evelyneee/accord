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
    var matches: [Channel] {
        var matches: [Channel] = Array(Array(Array(Storage.folders.compactMap { $0.guilds.compactMap { $0.channels.filter { $0.name?.lowercased().contains(text.lowercased()) ?? true } } }).joined()).joined())
        let dmMatches: [Channel] = Storage.privateChannels.filter { $0.computedName.lowercased().contains(text.lowercased()) }
        matches.append(contentsOf: dmMatches)
        return matches
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

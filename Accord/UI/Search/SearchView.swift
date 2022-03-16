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
        var matches: [Channel] = Array(Array(Array(ServerListView.folders.compactMap { $0.guilds.compactMap { $0.channels?.filter { $0.name?.lowercased().contains(text.lowercased()) ?? true } } }).joined()).joined())
        let dmMatches: [Channel] = ServerListView.privateChannels.filter { $0.computedName.lowercased().contains(text.lowercased()) }
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
            }
            VStack {
                Spacer().frame(height: 25)
                ForEach(matches.prefix(10), id: \.id) { channel in
                    Button(action: {
                        MentionSender.shared.select(channel: channel)
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        HStack {
                            if let icon = channel.guild_icon {
                                Attachment(iconURL(channel.guild_id, icon))
                                    .equatable()
                                    .clipShape(Circle())
                                    .frame(width: 19, height: 19)
                            } else if channel.recipients?.count == 1 {
                                Attachment(pfpURL(channel.recipients?[0].id, channel.recipients?[0].avatar, discriminator: channel.recipients?[0].discriminator ?? "0005"))
                                    .equatable()
                                    .clipShape(Circle())
                                    .frame(width: 19, height: 19)
                            }
                            Text(channel.computedName)
                                .foregroundColor(Color(NSColor.textColor))
                            if let guildName = channel.guild_name {
                                Text(" — \(guildName)")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    })
                    .buttonStyle(BorderlessButtonStyle())
                }
                Spacer()
            }.frame(height: 300)
        }
        .frame(width: 400)
        .padding()
        .onExitCommand {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

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
    @State var results = [Channel]()
    @Environment(\.presentationMode) var presentationMode
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
                ForEach(Array(Array(Array(ServerListView.folders.compactMap { $0.guilds.compactMap { $0.channels?.filter { $0.name?.contains(text) ?? true } } }).joined()).joined()).prefix(5), id: \.id) { channel in
                    Button(action: { [unowned channel] in
                        MentionSender.shared.select(channel: channel)
                        presentationMode.wrappedValue.dismiss()
                    }, label: { [unowned channel] in
                        HStack {
                            Attachment(iconURL(channel.guild_id, channel.guild_icon))
                                .clipShape(Circle())
                                .frame(width: 37, height: 37)
                            Text(channel.name ?? "Unknown channel")
                                .font(.title3)
                            Spacer()
                        }
                    })
                    .buttonStyle(BorderlessButtonStyle())
                }
                Spacer()
            }.frame(height: 250)
        }
        .frame(width: 400)
        .padding()
        .onAppear {
            print(ServerListView.folders.compactMap { $0.guilds.compactMap { $0.channels?.compactMap { $0.guild_icon } } })
        }
    }
}

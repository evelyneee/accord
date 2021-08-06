//
// EmotesView.swift
// Accord
//
// Created by evelyn on 12.02.21
//

import SwiftUI

// actual view
struct EmotesView: View, Equatable {
    static func == (lhs: EmotesView, rhs: EmotesView) -> Bool {
        return true
    }
    
    @State var searchenabled = true
    var columns: [GridItem] = [
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0)
    ]
    @Binding var chatText: String
    @State var SearchText: String = ""
    @State var minimumWidth = 275
    @State var recentMax = 8
    @Environment(\.openURL) var openURL
    @State var recentsenabled = true
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(Array(AllEmotes.shared.allEmotes.keys), id: \.self) { key in
                        Section(header: Text(key.components(separatedBy: "$")[1])) {
                            LazyVGrid(columns: columns) {
                                ForEach((AllEmotes.shared.allEmotes[key] ?? []), id: \.self) { emote in
                                    Button(action: {
                                        chatText.append(contentsOf: "<\(emote.animated ?? false ? "a" : ""):\(emote.name):\(emote.id)>")
                                    }) {
                                        VStack {
                                            HoveredAttachment("https://cdn.discordapp.com/emojis/\(emote.id)").equatable()
                                                .frame(width: 25, height: 25)
                                        }
                                        .frame(width: 30, height: 30)
                                    }
                                    .buttonStyle(EmoteButton())
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
    }
}

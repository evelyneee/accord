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
    @State var recentsenabled = true
    @State var search = ""
    var body: some View {
        HStack {
            ZStack(alignment: .top) {

                ScrollView {
                    Spacer().frame(height: 45)
                    LazyVStack(alignment: .leading) {
                        if search == "" {
                            ForEach(Array(AllEmotes.shared.allEmotes.keys), id: \.self) { key in
                                Section(header: Text(key.components(separatedBy: "$")[1])) {
                                    LazyVGrid(columns: columns) {
                                        ForEach((AllEmotes.shared.allEmotes[key] ?? []), id: \.self) { emote in
                                            Button(action: { [weak emote] in
                                                chatText.append(contentsOf: "<\(emote?.animated ?? false ? "a" : ""):\(emote?.name ?? ""):\(emote?.id ?? "")>")
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

                        } else {
                            LazyVGrid(columns: columns) {
                                ForEach(AllEmotes.shared.allEmotes.values.flatMap { $0 }.filter { $0.name.contains(search) }, id: \.self) { emote in
                                    Button(action: { [weak emote] in
                                        chatText.append(contentsOf: "<\(emote?.animated ?? false ? "a" : ""):\(emote?.name ?? ""):\(emote?.id ?? "")>")
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
                .padding()
                TextField("Search emotes", text: $search)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background

            }
        }
        .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
    }
}

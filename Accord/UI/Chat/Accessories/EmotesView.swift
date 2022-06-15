//
// EmotesView.swift
// Accord
//
// Created by evelyn on 12.02.21
//

import SwiftUI

// actual view
@available(macOS 11.0, *)
struct EmotesView: View, Equatable {
    static func == (_: EmotesView, _: EmotesView) -> Bool {
        true
    }

    init(chatText: Binding<String>? = nil, onSelect: @escaping ((DiscordEmote) -> Void) = { _ in }) {
        _chatText = chatText ?? Binding.constant("")
        self.onSelect = onSelect
    }

    @State var searchenabled = true
    var columns: [GridItem] = GridItem.multiple(count: 10, spacing: 0)
    @Binding var chatText: String
    var onSelect: (DiscordEmote) -> Void
    @State var SearchText: String = ""
    @State var minimumWidth = 275
    @State var recentMax = 8
    @State var recentsenabled = true
    @State var search = ""
    
    @Environment(\.dismiss)
    var dismiss
    
    var body: some View {
        HStack {
            ZStack(alignment: .top) {
                ScrollView {
                    Spacer().frame(height: 45)
                    LazyVStack(alignment: .leading) {
                        if search == "" {
                            ForEach(Array(Emotes.emotes.keys), id: \.self) { key in
                                Section(header: Text(key.components(separatedBy: "$")[1])) {
                                    LazyVGrid(columns: columns) {
                                        ForEach(Emotes.emotes[key] ?? [], id: \.id) { emote in
                                            Button(action: {
                                                chatText.append(contentsOf: "<\(emote.animated ?? false ? "a" : ""):\(emote.name):\(emote.id)> ")
                                                onSelect(emote)
                                                self.dismiss()
                                                print(cdnURL + "/emojis/\(emote.id).png?size=24")
                                            }) {
                                                VStack {
                                                    HoveredAttachment(cdnURL + "/emojis/\(emote.id).png?size=24").equatable()
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
                                ForEach(Emotes.emotes.values.flatMap { $0 }.filter { $0.name.contains(search) }, id: \.id) { emote in
                                    Button(action: {
                                        chatText.append(contentsOf: "<\(emote.animated ?? false ? "a" : ""):\(emote.name):\(emote.id)> ")
                                        onSelect(emote)
                                        self.dismiss()
                                    }) {
                                        HoveredAttachment(cdnURL + "/emojis/\(emote.id).png?size=24").equatable()
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
                    .background(Material.thick) // blurred background
                    .onSubmit {
                        self.onSelect(DiscordEmote(id: "stock", name: self.search))
                        self.dismiss()
                    }
            }
        }
        .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
    }
}

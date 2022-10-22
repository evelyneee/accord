//
// EmotesView.swift
// Accord
//
// Created by evelyn on 12.02.21
//

import SwiftUI

// actual view
struct EmotesView: View, Equatable {
    static func == (_: EmotesView, _: EmotesView) -> Bool {
        true
    }

    init(chatText: Binding<String>? = nil, onSelect: @escaping ((DiscordEmote) -> Void) = { _ in }) {
        _chatText = chatText ?? Binding.constant("")
        self.onSelect = onSelect
    }

    @State var searchenabled = true
    var columns: [GridItem] = GridItem.multiple(count: 8, spacing: 0)
    @Binding var chatText: String
    var onSelect: (DiscordEmote) -> Void
    @State var SearchText: String = ""
    @State var minimumWidth = 275
    @State var recentMax = 8
    @State var recentsenabled = true
    @State var search = ""
    
    enum Selection: Hashable {
        case emotes
        case stickers
    }
    
    @State var selection: Selection = .emotes
    
    @Environment(\.dismiss)
    var dismiss
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    var body: some View {
        HStack {
            ZStack(alignment: .top) {
                VStack {
                    TextField("Search emotes", text: $search)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Material.thick) // blurred background
                        .onSubmit {
                            self.onSelect(DiscordEmote(id: "stock", name: self.search))
                            self.dismiss()
                        }
                    TabView(selection: self.$selection) {
                        ScrollView {
                            Spacer().frame(height: 45)
                            LazyVStack(alignment: .leading) {
                                if search.isEmpty {
                                    let keys = Array(Storage.emotes.keys)
                                    let nonEmptyKeys = keys.filter { !(Storage.emotes[$0] ?? []).isEmpty }
                                    ForEach(nonEmptyKeys, id: \.self) { key in
                                        if !(Storage.emotes[key]?.isEmpty == false) {
                                            Section(header: Text(key.components(separatedBy: "$")[1])) {
                                                LazyVGrid(columns: columns) {
                                                    ForEach(Storage.emotes[key] ?? [], id: \.id) { emote in
                                                        Button(action: {
                                                            chatText.append(contentsOf: "<\(emote.animated ?? false ? "a" : ""):\(emote.name):\(emote.id)> ")
                                                            onSelect(emote)
                                                            self.dismiss()
                                                        }) {
                                                            VStack {
                                                                HoveredAttachment(cdnURL + "/emojis/\(emote.id).png?size=48").equatable()
                                                                    .frame(width: 29, height: 29)
                                                                    .fixedSize()
                                                            }
                                                            .frame(width: 30, height: 30)
                                                            .fixedSize()
                                                        }
                                                        .buttonStyle(EmoteButton())
                                                        .fixedSize()
                                                    }
                                                }
                                            }
                                        }
                                    }

                                } else {
                                    LazyVGrid(columns: columns) {
                                        ForEach(Storage.emotes.values.flatMap { $0 }.filter { $0.name.contains(search) }, id: \.id) { emote in
                                            Button(action: {
                                                chatText.append(contentsOf: "<\(emote.animated ?? false ? "a" : ""):\(emote.name):\(emote.id)> ")
                                                onSelect(emote)
                                                self.dismiss()
                                            }) {
                                                HoveredAttachment(cdnURL + "/emojis/\(emote.id).png?size=48").equatable()
                                                    .frame(width: 29, height: 29)
                                                    .fixedSize()
                                            }
                                            .fixedSize()
                                            .buttonStyle(EmoteButton())
                                            .fixedSize()
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .tabItem({Text("Emotes")})
                        StickersView()
                            .tabItem({Text("Stickers")})
                    }
                }
            }
        }
        .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
    }
}

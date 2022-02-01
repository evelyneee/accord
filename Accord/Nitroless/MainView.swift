//
// Views.swift
// NitrolessMac
//
// Created by evelyn on 12/02/21
//

import Combine
import SwiftUI

struct EmoteButton: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CGFloat(0.85) : 1.0)
            .animation(.spring())
            .padding(.bottom, 3)
    }
}

struct NitrolessEmote: Decodable {
    var name: String
    var type: String
}

// actual view
@available(macOS 11.0, *)
struct NitrolessView: View, Equatable {
    static func == (_: NitrolessView, _: NitrolessView) -> Bool {
        true
    }

    fileprivate static let nitrolessRoot = "https://raw.githubusercontent.com/evelyneee/Repo/main/"

    @State var searchenabled = true
    var columns: [GridItem] = GridItem.multiple(count: 8, spacing: 1)
    @Binding var chatText: String
    @State var allEmotes: [String: String] = [:]
    @State var search: String = ""
    @State var cancellable: AnyCancellable? = nil
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TextField("Search for emotes", text: $search)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                LazyVGrid(columns: columns) {
                    ForEach(Array(allEmotes.keys.filter { search != "" ? $0.contains(search) : true }), id: \.self) { key in
                        Button(action: {
                            guard let emote = allEmotes[key] else { return }
                            chatText.append(contentsOf: "\(Self.nitrolessRoot)emotes/\(key)\(emote)")
                        }) {
                            VStack {
                                HoveredAttachment("\(Self.nitrolessRoot)emotes/\(key)\(allEmotes[key] ?? "")").equatable()
                                    .frame(width: 20, height: 20)
                            }
                            .frame(width: 30, height: 30)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            imageQueue.async {
                self.cancellable = RequestPublisher.fetch([NitrolessEmote].self, url: URL(string: "\(Self.nitrolessRoot)emotes.json"))
                    .replaceError(with: [])
                    .sink { emotes in
                        for emote in emotes {
                            allEmotes[emote.name] = emote.type
                        }
                    }
            }
        }
    }
}

//
//  AsyncMarkdown.swift
//  Accord
//
//  Created by evelyn on 2022-01-22.
//

import Combine
import Foundation
import SwiftUI

final class AsyncMarkdownModel: ObservableObject {
    
    @MainActor
    init(text: String) {
        markdown = Text(text)
        self.channelInfo = nil
    }

    @MainActor @Published
    var markdown: Text
    
    @MainActor @Published
    var loaded: Bool = false
    
    @MainActor @Published
    var hasEmojiOnly: Bool = false

    private var cancellable: AnyCancellable?
    static let queue = DispatchQueue(label: "textQueue")
    
    var channelInfo: (String, String)?

    @_optimize(speed)
    func make(text: String, usernames: [String:String], allowLinkShortening: Bool) {
        Self.queue.async { [weak self] in
            let emojis = text.hasEmojisOnly
            guard (text.contains("*") ||
                   text.contains("~") ||
                   text.contains("/") ||
                   text.contains("_") ||
                   text.contains(">") ||
                   text.contains("<") ||
                   text.contains("`")) ||
                    text.count > 100,
                  let channelInfo = self?.channelInfo else {
                guard let self else { return }
                DispatchQueue.main.async {
                    self.hasEmojiOnly = emojis
                    self.loaded = true
                }
                return
            }
            self?.cancellable = Markdown.markAll(text: text, usernames, font: emojis, allowLinkShortening: allowLinkShortening, channelInfo: channelInfo)
                .replaceError(with: Text(text))
                .sink { [weak self] text in
                    DispatchQueue.main.async {
                        self?.loaded = true
                        self?.markdown = text
                        self?.hasEmojiOnly = emojis
                    }
                }
            DispatchQueue.main.async {
                self?.hasEmojiOnly = emojis
            }
        }
    }
}

struct AsyncMarkdown: View, Equatable {
    static func == (_ lhs: AsyncMarkdown, _ rhs: AsyncMarkdown) -> Bool {
        lhs.text == rhs.text
    }

    @StateObject var model: AsyncMarkdownModel
    @Binding var text: String
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    var linkShortening: Bool

    @Environment(\.guildID)
    var guildID: String
    
    @Environment(\.channelID)
    var channelID: String
    
    @MainActor
    init(_ text: String, binded: Binding<String>? = nil, linkShortening: Bool = false) {
        _model = StateObject(wrappedValue: AsyncMarkdownModel(text: text))
        _text = binded ?? .constant(text)
        self.linkShortening = linkShortening
    }

    @ViewBuilder
    var body: some View {
        Group {
            if !model.hasEmojiOnly || model.loaded {
                if #available(macOS 13.0, *) {
                    model.markdown
                        .textSelection(.enabled)
                        .font(self.model.hasEmojiOnly ? .system(size: 48) : .chatTextFont)
                        .onChange(of: self.text, perform: { [weak model] text in
                            model?.make(text: text, usernames: Storage.usernames, allowLinkShortening: linkShortening)
                        })
                        .onAppear { [weak model] in
                            model?.channelInfo = (guildID, channelID)
                            model?.make(text: text, usernames: Storage.usernames, allowLinkShortening: linkShortening)
                        }
                } else {
                    model.markdown
                        .textSelection(.enabled)
                        .font(self.model.hasEmojiOnly ? .system(size: 48) : .chatTextFont)
                        .fixedSize(horizontal: false, vertical: true)
                        .onChange(of: self.text, perform: { [weak model] text in
                            model?.make(text: text, usernames: Storage.usernames, allowLinkShortening: linkShortening)
                        })
                        .onAppear { [weak model] in
                            model?.channelInfo = (guildID, channelID)
                            model?.make(text: text, usernames: Storage.usernames, allowLinkShortening: linkShortening)
                        }
                }
            }
        }
    }
}

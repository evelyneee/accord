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
    }

    @MainActor @Published
    var markdown: Text
    
    @MainActor @Published
    var loaded: Bool = false
    
    @MainActor @Published
    var hasEmojiOnly: Bool = false

    private var cancellable: AnyCancellable?
    static let queue = DispatchQueue(label: "textQueue", attributes: .concurrent)

    @_optimize(speed)
    func make(text: String, usernames: [String:String]) {
        Self.queue.async { [weak self] in
            let emojis = text.hasEmojisOnly
            guard (text.contains("*") ||
                   text.contains("~") ||
                   text.contains("/") ||
                   text.contains("_") ||
                   text.contains(">") ||
                   text.contains("<") ||
                   text.contains("`")) ||
                    text.count > 100 else {
                DispatchQueue.main.async {
                    self?.hasEmojiOnly = emojis
                    self?.loaded = true
                }
                return
            }
            self?.cancellable = Markdown.markAll(text: text, usernames, font: emojis)
                .replaceError(with: Text(text))
                .sink { [weak self] text in
                    DispatchQueue.main.async {
                        self?.loaded = true
                        self?.markdown = text
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

    @MainActor
    init(_ text: String, binded: Binding<String>? = nil) {
        _model = StateObject(wrappedValue: AsyncMarkdownModel(text: text))
        _text = binded ?? .constant(text)
    }

    @ViewBuilder
    var body: some View {
        if !model.hasEmojiOnly || model.loaded {
            model.markdown
                .textSelection(.enabled)
                .font(self.model.hasEmojiOnly ? .system(size: 48, design: .rounded) : .chatTextFont)
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: self.text, perform: { [weak model] text in
                    model?.make(text: text, usernames: Storage.usernames)
                })
                .onAppear { [weak model] in
                    model?.make(text: text, usernames: Storage.usernames)
                }
        }
    }
}

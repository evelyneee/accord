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
    init(text: String) {
        markdown = Text(text)
    }

    @Published var markdown: Text
    @Published var loaded: Bool = false

    var hasEmojiOnly: Bool = false

    private var cancellable: AnyCancellable?
    static let queue = DispatchQueue(label: "textQueue", attributes: .concurrent)

    func make(text: String) {
        Self.queue.async { [weak self] in
            let emojis = text.hasEmojisOnly
            self?.cancellable = Markdown.markAll(text: text, Storage.usernames, font: emojis)
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

    init(_ text: String, binded: Binding<String>? = nil) {
        _model = StateObject(wrappedValue: AsyncMarkdownModel(text: text))
        _text = binded ?? Binding.constant(text)
    }

    @ViewBuilder
    var body: some View {
        if !model.hasEmojiOnly || model.loaded {
            model.markdown
                .textSelection(.enabled)
                .font(self.model.hasEmojiOnly ? .system(size: 48) : .chatTextFont)
                .animation(nil, value: UUID())
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: self.text, perform: { [weak model] text in
                    model?.make(text: text)
                })
                .onAppear { [weak model] in
                    model?.make(text: text)
                }
        }
    }
}

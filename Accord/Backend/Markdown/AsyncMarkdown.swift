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
        make(text: text)
    }

    @Published var markdown: Text
    @Published var loaded: Bool = false
    
    var hasEmojiOnly: Bool = false

    private var cancellable: AnyCancellable?
    
    func make(text: String) {
        DispatchQueue.global().async { [weak self] in
            let emojis = text.hasEmojisOnly
            self?.cancellable = Markdown.markAll(text: text, Storage.usernames, font: emojis)
                .replaceError(with: Text(text))
                .receive(on: RunLoop.main)
                .sink { [weak self] text in
                    self?.loaded = true
                    self?.markdown = text
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
        self._text = binded ?? Binding.constant(text)
    }
    
    @ViewBuilder
    var body: some View {
        if !model.hasEmojiOnly || model.loaded {
            if #available(macOS 12.0, *) {
                model.markdown
                    .textSelection(.enabled)
                    .font(self.model.hasEmojiOnly ? .system(size: 48) : .chatTextFont)
                    .animation(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .onChange(of: self.text, perform: { text in
                        self.model.make(text: text)
                    })
            } else {
                model.markdown
                    .font(self.model.hasEmojiOnly ? .system(size: 48) : .chatTextFont)
                    .animation(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .onChange(of: self.text, perform: { text in
                        self.model.make(text: text)
                    })
            }
        }
    }
}

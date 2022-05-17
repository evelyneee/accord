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
    @Published var hasEmojiOnly: Bool = false
    @Published var loaded: Bool = false

    func make(text: String) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let emojis = text.hasEmojisOnly
            Markdown.markAll(text: text, Storage.usernames, font: emojis)
                .replaceError(with: Text(text))
                .receive(on: RunLoop.main)
                .assign(to: &self.$markdown)
            DispatchQueue.main.async {
                self.loaded = true
                self.hasEmojiOnly = text.hasEmojisOnly
            }
        }
    }
}

@available(macOS 12.0, *)
extension View {
    @ViewBuilder
    func textSelectionBool(_ selected: Bool) -> some View {
        if selected {
            self.textSelection(.enabled)
        } else {
            self.textSelection(.disabled)
        }
    }
}

struct AsyncMarkdown: View, Equatable {
    static func == (_ lhs: AsyncMarkdown, _ rhs: AsyncMarkdown) -> Bool {
        lhs.model.markdown == rhs.model.markdown
    }

    @StateObject var model: AsyncMarkdownModel
    @Binding var text: String

    init(_ text: String, binded: Binding<String> = Binding.constant("")) {
        _model = StateObject(wrappedValue: AsyncMarkdownModel(text: text))
        self._text = binded
    }
    
    var body: some View {
        if #available(macOS 12.0, *) {
            model.markdown
                .textSelectionBool(!model.hasEmojiOnly)
                .font(self.model.hasEmojiOnly ? .system(size: 48) : .chatTextFont)
                .animation(nil)
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: self.text, perform: { text in
                    self.model.make(text: text)
                })
                .if(!model.loaded && model.hasEmojiOnly, transform: { $0.hidden() })
        } else {
            model.markdown
                .font(self.model.hasEmojiOnly ? .system(size: 48) : .chatTextFont)
                .animation(nil)
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: self.text, perform: { text in
                    self.model.make(text: text)
                })
                .if(!model.loaded && model.hasEmojiOnly, transform: { $0.hidden() })
        }
    }
}

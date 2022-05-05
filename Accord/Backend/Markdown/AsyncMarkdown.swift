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
    
    private func make(text: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.hasEmojiOnly = text.hasEmojisOnly
            Markdown.markAll(text: text, Storage.usernames, font: self.hasEmojiOnly)
                .replaceError(with: Text(text))
                .receive(on: RunLoop.main)
                .assign(to: &self.$markdown)
            DispatchQueue.main.async {
                self.loaded = true
            }
        }
    }
}

struct AsyncMarkdown: View, Equatable {
    static func == (_ lhs: AsyncMarkdown, _ rhs: AsyncMarkdown) -> Bool {
        lhs.model.markdown == rhs.model.markdown
    }

    @StateObject var model: AsyncMarkdownModel

    init(_ text: String) {
        _model = StateObject(wrappedValue: AsyncMarkdownModel(text: text))
    }

    var body: some View {
        model.markdown
            .font(self.model.hasEmojiOnly ? .system(size: 48) : .chatTextFont)
            .animation(nil)
            .fixedSize(horizontal: false, vertical: true)
            .if(!model.loaded && model.hasEmojiOnly, transform: { $0.hidden() })
    }
}

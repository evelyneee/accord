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
    init(text: String, font: Bool) {
        markdown = Text(text)
        make(text: text, font: font)
    }

    @Published var markdown: Text
    var loaded = false
    
    private func make(text: String, font: Bool) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            Markdown.markAll(text: text, Storage.usernames, font: font)
                .replaceError(with: Text(text))
                .receive(on: RunLoop.main)
                .assign(to: &self.$markdown)
        }
    }
}

struct AsyncMarkdown: View, Equatable {
    static func == (_: AsyncMarkdown, _: AsyncMarkdown) -> Bool {
        true
    }

    @StateObject var model: AsyncMarkdownModel
    var font: Bool

    init(_ text: String, font: Bool = false) {
        _model = StateObject(wrappedValue: AsyncMarkdownModel(text: text, font: font))
        self.font = font
    }

    var body: some View {
        model.markdown
            .font(self.font ? .system(size: 48) : .chatTextFont)
            .animation(nil)
            .fixedSize(horizontal: false, vertical: true)
            .if(model.loaded && self.font, transform: { $0.hidden() })
    }
}

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
    
    init (text: String) {
        self.markdown = Text(text)
        self.make(text: text)
    }
    
    @Published var markdown: Text
    private var cancellable: AnyCancellable? = nil
    
    private func make(text: String) {
        self.cancellable = Markdown.markAll(text: text, Storage.usernames)
            .subscribe(on: textQueue)
            .receive(on: textQueue)
            .replaceError(with: Text(text))
            .receive(on: DispatchQueue.main)
            .sink { res in
                self.markdown = res
            }
    }
}

struct AsyncMarkdown: View, Equatable {
    
    static func == (lhs: AsyncMarkdown, rhs: AsyncMarkdown) -> Bool {
        return true
    }
    
    @StateObject var model: AsyncMarkdownModel
    
    init(_ text: String) {
        _model = StateObject(wrappedValue: AsyncMarkdownModel(text: text))
    }
    
    var body: some View {
        model.markdown
    }
}

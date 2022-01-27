//
//  AsyncMarkdown.swift
//  Accord
//
//  Created by evelyn on 2022-01-22.
//

import Foundation
import SwiftUI
import Combine

struct AsyncMarkdown: View {
    private var _text: String
    @State private var cancellable: AnyCancellable? = nil
    @State var markdown: Text?
    init(_ text: String) {
        self._text = text
        self.markdown = nil
        self.cancellable = nil
    }
    
    private func make() {
        textQueue.async {
            self.cancellable = Markdown.markAll(text: self._text, Storage.usernames)
                .replaceError(with: Text(self._text))
                .sink { res in
                    self.markdown = res
                }
        }
    }
    
    var body: some View {
        HStack {
            markdown ?? Text(_text)
        }
        .onAppear {
            make()
        }
    }
}

//
//  Highlighting.swift
//  Accord
//
//  Created by evelyn on 2022-05-19.
//

import Foundation
import SwiftUI

@usableFromInline
enum Highlighting {
    @available(macOS 12, *) @inlinable
    static func parse(_ text: String) -> AttributedString {
        let base = [0, 1, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6, 6]
        let invalid = !Array(text)
            .filter { char in
                guard let scalar = char.unicodeScalars.first else { return false }
                return !CharacterSet.letters.contains(scalar)
            }
            .isEmpty
        guard !invalid else { return AttributedString(text) }
        var letters = Array(text)
        let index = base.indices.contains(letters.count) ? base[letters.count] : 7
        let initial = String(letters[0 ..< index])
        letters.removeSubrange(0 ..< index)
        let remaining = String(letters)
        var container = AttributeContainer()
        container.font = .system(size: 14).weight(.semibold).leading(.loose)
        var stockContainer = AttributeContainer()
        stockContainer.font = .system(size: 14).leading(.loose)
        return AttributedString(initial).settingAttributes(container) + AttributedString(remaining).settingAttributes(stockContainer)
    }
}

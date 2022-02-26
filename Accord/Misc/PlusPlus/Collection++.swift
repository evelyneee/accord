//
//  Collection++.swift
//  Accord
//
//  Created by evelyn on 2022-02-18.
//

import Foundation

extension Collection where Element: Identifiable {
    func generateKeyMap() -> [Element.ID: Int] {
        return self
            .enumerated()
            .compactMap { [$1.id: $0] }
            .reduce(into: [:]) { result, next in
                result.merge(next) { _, rhs in rhs }
            }
    }
}

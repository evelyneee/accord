//
//  Collection++.swift
//  Accord
//
//  Created by evelyn on 2022-02-18.
//

import Foundation
import Combine

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

extension Dictionary {
    func filterValues(isIncluded: (Self.Value) throws -> Bool) rethrows -> Self {
        return try self.filter { try isIncluded($0.value) }
    }
}

extension Collection {
    func jsonString() throws -> String? {
        let data = try JSONSerialization.data(withJSONObject: self, options: [])
        let jsonString = String(data: data, encoding: .utf8)
        return jsonString
    }
}

extension ArraySlice {
    typealias LiteralType = Array<Self.Element>
    func literal() -> LiteralType {
        return LiteralType(self)
    }
}

extension Slice where Base: Sequence {
    func literal() -> Base {
        return self.base
    }
}

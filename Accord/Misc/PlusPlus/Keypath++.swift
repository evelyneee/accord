//
//  Keypath++.swift
//  Accord
//
//  Created by evelyn on 2022-01-30.
//

import Foundation

extension Sequence {
    // example: ["uwu"].map(\.self)
    func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map { $0[keyPath: keyPath] }
    }
    func compactMap<T>(_ keyPath: KeyPath<Element, T?>) -> [T] {
        return compactMap { $0[keyPath: keyPath] }
    }
}

//
//  IncrementNumbers.swift
//  IncrementNumbers
//
//  Created by evelyn on 2021-10-17.
//

import Foundation
import CloudKit

prefix operator ++
postfix operator ++

prefix operator --
postfix operator --

infix operator &=

postfix operator ~~

public postfix func ~~<T: Collection & ExpressibleByArrayLiteral>(_ x: T?) -> T {
    if let x = x {
        return x
    } else {
        return []
    }
}

@discardableResult public prefix func ++<T: Numeric>(_ x: inout T) -> T {
    x += 1
    return x
}

@discardableResult public postfix func ++<T: Numeric>(_ x: inout T) -> T {
    x += 1
    return x
}

@discardableResult public prefix func --<T: Numeric>(_ x: inout T) -> T {
    x -= 1
    return x
}

@discardableResult public postfix func --<T: Numeric>(_ x: inout T) -> T {
    x -= 1
    return x
}

public func &=<T: Equatable>(lhs: T, rhs: [T]) -> Bool {
    rhs.contains(lhs)
}

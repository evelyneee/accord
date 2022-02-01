//
//  IncrementNumbers.swift
//  IncrementNumbers
//
//  Created by evelyn on 2021-10-17.
//

import Foundation

prefix operator ++
postfix operator ++

prefix operator --
postfix operator --

infix operator &=

@discardableResult public prefix func ++ <T: Numeric>(_ x: inout T) -> T {
    x += 1
    return x
}

@discardableResult public postfix func ++ <T: Numeric>(_ x: inout T) -> T {
    x += 1
    return x
}

@discardableResult public prefix func -- <T: Numeric>(_ x: inout T) -> T {
    x -= 1
    return x
}

@discardableResult public postfix func -- <T: Numeric>(_ x: inout T) -> T {
    x -= 1
    return x
}

public func &= <T: Equatable>(lhs: T, rhs: [T]) -> Bool {
    rhs.contains(lhs)
}

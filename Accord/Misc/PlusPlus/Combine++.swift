//
//  Combine++.swift
//  Accord
//
//  Created by evelyn on 2022-01-02.
//

import Combine
import Foundation

extension Set where Element: Cancellable {
    func invalidateAll() {
        forEach { $0.cancel() }
    }
}

extension Publisher {
    func eraseToAny() -> AnyPublisher<Self.Output, Error> {
        mapError { $0 as Error }.eraseToAnyPublisher()
    }
}

precedencegroup ForwardApplication {
    associativity: left
    higherThan: AssignmentPrecedence
}

infix operator |> : ForwardApplication

public func |> <T, U>(x: T, f: (T) -> U) -> U {
    return f(x)
}

public func |> <T, U>(x: T, keyPath: KeyPath<T, U>) -> U {
    return x[keyPath: keyPath]
}

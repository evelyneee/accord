//
//  Combine++.swift
//  Accord
//
//  Created by evelyn on 2022-01-02.
//

import Combine
import Foundation
import os

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

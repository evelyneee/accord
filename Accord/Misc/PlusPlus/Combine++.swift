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

    func debugWarnNoMainThread(_ file: String = #file, _ line: Int = #line, _ function: String = #function) -> Self {
        guard Thread.isMainThread else { return self }
        #if DEBUG
            os_log(
                .fault, dso: rw.dso, log: rw.log,
                "An action was performed on the main thread by %@ in %@",
                function,
                "\(file.components(separatedBy: "/").suffix(2).joined(separator: "/")):\(String(line))"
            )
        #endif
        return self
    }
}

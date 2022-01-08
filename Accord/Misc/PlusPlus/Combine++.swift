//
//  Combine++.swift
//  Accord
//
//  Created by evelyn on 2022-01-02.
//

import Foundation
import Combine
import os

extension Set where Element: Cancellable {
    func invalidateAll() {
        self.forEach { $0.cancel() }
    }
}

extension Publisher {
    func eraseToAny() -> AnyPublisher<Self.Output, Error> {
        self.mapError { $0 as Error }.eraseToAnyPublisher()
    }
    func warnNoMainThread(_ file: String = #file, _ line: Int = #line, _ function: String = #function) -> Self {
        guard Thread.isMainThread else { return self }

        os_log(
           .fault, dso: rw.dso, log: rw.log,
           "An action was performed on the main thread by %@ in %@",
           function,
           "\(file.components(separatedBy: "/").suffix(2).joined(separator: "/")):\(String(line))"
         )
        return self
    }
    func debugWarnNoMainThread(_ file: String = #file, _ line: Int = #line, _ function: String = #function)  -> Self {
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

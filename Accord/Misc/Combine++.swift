//
//  Combine++.swift
//  Accord
//
//  Created by evelyn on 2022-01-02.
//

import Foundation
import Combine

extension Set where Element: Cancellable {
    func invalidateAll() {
        self.forEach { $0.cancel() }
    }
}

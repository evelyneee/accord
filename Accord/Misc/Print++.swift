//
//  Print++.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation

public func print(_ object: Any...) {
    #if DEBUG
    for item in object {
        Swift.print("[Accord]", item)
    }
    #endif
}

public func print(_ object: Any) {
    #if DEBUG
    Swift.print("[Accord]", object)
    #endif
}

public func releaseModePrint(_ object: Any...) {
    Swift.print("\(Date()) [Accord] ")
    for item in object {
        Swift.print(String(describing: item))
    }
}

public func releaseModePrint(_ object: Any) {
    Swift.print("[Accord] \(String(describing: object))")
}

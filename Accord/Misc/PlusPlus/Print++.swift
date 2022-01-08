//
//  Print++.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation

public var ENABLE_LINE_LOGGING: Bool = true
public var ENABLE_FILE_EXTENSION_LOGGING: Bool = false

public func print<T>(_ items: T..., file: String = #file, line: Int = #line, separator: String = " ") {
    let file = ENABLE_FILE_EXTENSION_LOGGING ?
    file.components(separatedBy: "/").last ?? "Accord" :
    file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? "Accord"
    let lineString = ENABLE_LINE_LOGGING ? ":\(String(line))" : ""
    var out = String()
    for item in items {
        if type(of: item) is AnyClass {
            dump(item, to: &out)
        } else {
            out.append(String(describing: item))
        }
        out.append(separator)
    }
    Swift.print("[\(file)\(lineString)]", out)
}

public func print(_ items: String..., file: String = #file, line: Int = #line, separator: String = " ") {
    let file = ENABLE_FILE_EXTENSION_LOGGING ?
    file.components(separatedBy: "/").last ?? "Accord" :
    file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? "Accord"
    let lineString = ENABLE_LINE_LOGGING ? ":\(String(line))" : ""
    Swift.print("[\(file)\(lineString)]", items.joined(separator: " "))
}

public func print(_ items: Any..., file: String = #file) {
    let file = ENABLE_FILE_EXTENSION_LOGGING ?
    file.components(separatedBy: "/").last ?? "Accord" :
    file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? "Accord"
    var out = String()
    for item in items {
        if type(of: item) is AnyClass {
            dump(item, to: &out)
        } else {
            out.append(String(describing: item))
        }
        out.append(" ")
    }
    Swift.print("[\(file)]", out )
}

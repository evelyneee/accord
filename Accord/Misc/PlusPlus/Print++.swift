//
//  Print++.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation

private let ENABLE_LINE_LOGGING: Bool = true
private let ENABLE_FILE_EXTENSION_LOGGING: Bool = false

public func dprint(
    _ items: Any..., // first variadic parameter
    file: String = #fileID, // file name which is not meant to be specified
    _ items2: Any..., // second variadic parameter
    line: Int = #line, // line number
    separator: String = " "
) {
    let file = ENABLE_FILE_EXTENSION_LOGGING ?
        file.components(separatedBy: "/").last ?? "Accord" :
        file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? "Accord"
    let line = ENABLE_LINE_LOGGING ? ":\(String(line))" : ""
    log(items: items, file: file, line: line, separator: separator)
}

// this is meant to override the print function globally in scope
// the normal signature of the print function is print(_ items: Any...)
// if we wanna override it, we can't use a single variadic parameter because
// there is an error about ambiguous usage
// tldr: very cursed code, do not touch
public func print(
    _ items: Any..., // first variadic parameter
    file: String = #fileID, // file name which is not meant to be specified
    _ items2: Any..., // second variadic parameter
    line: Int = #line, // line number
    separator: String = " "
) {
    let file = ENABLE_FILE_EXTENSION_LOGGING ?
        file.components(separatedBy: "/").last ?? "Accord" :
        file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? "Accord"
    let line = ENABLE_LINE_LOGGING ? ":\(String(line))" : ""
    log(items: items, file: file, line: line, separator: separator)
}

// this function exists to override the print function
// when there is only one item to print
// since the other function uses two variadic parameters it doesn't work
// when there is one element
public func print(
    _ item: Any,
    file: String = #fileID,
    line: Int = #line
) {
    let file = ENABLE_FILE_EXTENSION_LOGGING ?
        file.components(separatedBy: "/").last ?? "Accord" :
        file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? "Accord"
    let line = ENABLE_LINE_LOGGING ? ":\(String(line))" : ""
    log(items: [item], file: file, line: line)
}

private func log<T>(items: [T], file: String, line: String? = nil, separator: String = " ") {
    var out = String()
    for item in items {
        if type(of: item) is AnyClass {
            out.append(String(reflecting: item))
        } else if let data = item as? Data {
            out.append(String(data: data, encoding: .utf8) ?? String(describing: item))
        } else {
            out.append(String(describing: item))
        }
        out.append(separator)
    }
    Swift.print("[\(file)\(line ?? "")]", out)
}

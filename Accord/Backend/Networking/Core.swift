//
//  Core.swift
//  Accord
//
//  Created by evelyn on 2022-01-21.
//

import Foundation

final class NetworkCore {
    static var shared = NetworkCore()
    private(set) var connected = true
    init() {
        let url = URL(string: "\(rootURL)/gateway")!
        let data = try? Data(contentsOf: url)
        if data == nil {
            AccordApp.error(text: "Offline", additionalDescription: "Check your network connection")
            connected = false
        } else {
            connected = true
        }
    }
}

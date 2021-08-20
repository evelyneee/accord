//
//  AccordApp.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import Foundation
import SwiftUI
import AppKit

/// Use this variable to add a token to override keychain.
let tokenOverride = ""

public var logs: [String] = []
public var socketEvents: [[String:String]] = [] {
    didSet {

        #if DEBUG
        #else
        socketEvents.removeAll()
        #endif
    }
}

public func print(_ object: Any...) {
    #if DEBUG
    for item in object {
        logs.append(String(describing: item))
        Swift.print(item)
    }
    #endif
}

public func print(_ object: Any) {
    #if DEBUG
    logs.append(String(describing: object))
    Swift.print(object)
    #endif
}

public func releaseModePrint(_ object: Any...) {
    for item in object {
        Swift.print(item)
    }
}

public func releaseModePrint(_ object: Any) {
    Swift.print(object)
}

@main
struct AccordApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkMode ? .dark : nil)
                .onAppear(perform: {
                    if tokenOverride != "" {
                        _ = AccordCoreVars.init(tokenOverride)
                    }
                })
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

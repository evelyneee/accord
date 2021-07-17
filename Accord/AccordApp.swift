//
//  AccordApp.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import SwiftUI
import AppKit

public func print(_ object: Any...) {
    #if DEBUG
    for item in object {
        Swift.print(item)
    }
    #endif
}

public func print(_ object: Any) {
    #if DEBUG
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
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

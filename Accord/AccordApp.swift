//
//  AccordApp.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import Foundation
import SwiftUI
import AppKit

public var logs: [String] = []

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
                .preferredColorScheme(darkMode ? .dark : nil)
                .onAppear(perform: {
                    // AccordCoreVars.shared.loadPlugins()
                })
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidUnhide(_ notification: Notification) {
        if wss == nil {
            wss = WebSocket.init(url: URL(string: "wss://gateway.discord.gg?v=9&encoding=json"))
        }
    }
    func applicationDidHide(_ notification: Notification) {
        wss = nil
    }
}


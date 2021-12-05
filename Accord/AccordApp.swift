//
//  AccordApp.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import Foundation
import SwiftUI
import AppKit

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
    NSLog("[Accord] ")
    for item in object {
        NSLog(String(describing: item))
    }
}

public func releaseModePrint(_ object: Any) {
    NSLog("[Accord] \(String(describing: object))")
}

@main
struct AccordApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkMode ? .dark : nil)
                .onAppear(perform: {
                    appDelegate.fileNotifications()
                })
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    @objc func onWakeNote(note: NSNotification) {
        print("hi")
        if wss == nil {
            concurrentQueue.async {
                wss = WebSocket.init(url: URL(string: "wss://gateway.discord.gg?v=9&encoding=json"))
                _ = wss.ready()
            }
        }
    }
    @objc func onSleepNote(note: NSNotification) {
        wss.ws.cancel(with: .goingAway, reason: Data())
        wss = nil
    }
    func fileNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWakeNote(note:)),
            name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleepNote(note:)),
            name: NSWorkspace.willSleepNotification, object: nil)
    }
}

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
    @State var loaded: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("windowWidth") var windowWidth: Int = Int(NSApplication.shared.keyWindow?.frame.width ?? 1000)
    @AppStorage("windowHeight") var windowHeight: Int = Int(NSApplication.shared.keyWindow?.frame.height ?? 800)
    var body: some Scene {
        WindowGroup {
            GeometryReader { reader in
                ContentView(loaded: $loaded)
                    .preferredColorScheme(darkMode ? .dark : nil)
                    .onAppear(perform: {
                        print("hi")
                        appDelegate.fileNotifications()
                        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                            NSApplication.shared.keyWindow?.contentView?.window?.setFrame(NSRect(x: NSApp.keyWindow?.contentView?.window?.frame.minX ?? 0, y: NSApp.keyWindow?.contentView?.window?.frame.minY ?? 0, width: CGFloat(windowWidth), height: CGFloat(windowHeight)), display: true)
                        })
                    })
                    .onDisappear(perform: {
                        windowWidth = Int(reader.size.width)
                        windowHeight = Int(reader.size.height)
                        print(windowWidth, windowHeight)
                    })
            }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            SidebarCommands() // 1
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    @objc func onWakeNote(note: NSNotification) {
        print("hi")
        if wss == nil {
            concurrentQueue.async {
                wss.reset()
            }
        }
    }
    @objc func onSleepNote(note: NSNotification) {
        guard wss != nil else { return }
        wss.ws.cancel(with: .goingAway, reason: Data())
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

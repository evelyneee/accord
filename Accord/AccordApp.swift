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
    Swift.print("\(Date()) [Accord] ")
    for item in object {
        Swift.print(String(describing: item))
    }
}

public func releaseModePrint(_ object: Any) {
    NSLog("[Accord] \(String(describing: object))")
}

@main
struct AccordApp: App {
    @State var loaded: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var windowWidth: Int = Int(NSApplication.shared.keyWindow?.frame.width ?? 1000)
    @State var windowHeight: Int = Int(NSApplication.shared.keyWindow?.frame.height ?? 800)
    var body: some Scene {
        WindowGroup {
            if AccordCoreVars.shared.token == "" {
                LoginView()
            } else {
                GeometryReader { reader in
                    ContentView(loaded: $loaded)
                        .frame(minWidth: 800, minHeight: 600)
                        .preferredColorScheme(darkMode ? .dark : nil)
                        .onAppear(perform: {
                            self.windowWidth = UserDefaults.standard.integer(forKey: "windowWidth")
                            self.windowHeight = UserDefaults.standard.integer(forKey: "windowHeight")
                            if self.windowWidth == 0 {
                                self.windowWidth = 1000
                            }
                            if self.windowHeight == 0 {
                                self.windowHeight = 800
                            }
                            appDelegate.fileNotifications()
                            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                                NSApplication.shared.keyWindow?.contentView?.window?.setFrame(NSRect(x: NSApp.keyWindow?.contentView?.window?.frame.minX ?? 0, y: NSApp.keyWindow?.contentView?.window?.frame.minY ?? 0, width: CGFloat(windowWidth), height: CGFloat(windowHeight)), display: true)
                            })
                        })
                        .onDisappear(perform: {
                            loaded = false
                            UserDefaults.standard.set(Int(reader.size.width), forKey: "windowWidth")
                            UserDefaults.standard.set(Int(reader.size.height + 50), forKey: "windowHeight")
                            print(windowWidth, windowHeight)
                        })
                }
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
        if wss != nil {
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

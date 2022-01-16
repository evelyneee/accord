//
//  AccordApp.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import Foundation
import SwiftUI
import AppKit
import UserNotifications

@main
struct AccordApp: App {
    @State var loaded: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var windowWidth: Int = Int(NSApplication.shared.keyWindow?.frame.width ?? 1000)
    @State var windowHeight: Int = Int(NSApplication.shared.keyWindow?.frame.height ?? 800)
    @State var popup: Bool = false
    var body: some Scene {
        WindowGroup {
            if AccordCoreVars.token == "" {
                LoginView()
            } else {
                GeometryReader { reader in
                    ContentView(loaded: $loaded)
                        .frame(minWidth: 800, minHeight: 600)
                        .preferredColorScheme(darkMode ? .dark : nil)
                        .onAppear {
                            // AccordCoreVars.loadVersion()
                            // DispatchQueue(label: "socket").async {
                            //     let rpc = IPC().start()
                            // }
                            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                                if settings.authorizationStatus != .authorized {
                                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) {
                                        (granted, error) in
                                        if granted {
                                            print("lol")
                                        } else {
                                            print(error)
                                        }
                                    }
                                }
                            })
                            self.windowWidth = UserDefaults.standard.integer(forKey: "windowWidth")
                            self.windowHeight = UserDefaults.standard.integer(forKey: "windowHeight")
                            print(windowWidth, windowHeight)
                            if self.windowWidth == 0 {
                                self.windowWidth = 1000
                                UserDefaults.standard.set(1000, forKey: "windowWidth")
                            }
                            if self.windowHeight == 0 {
                                self.windowHeight = 800
                                UserDefaults.standard.set(Int(800 + 50), forKey: "windowHeight")
                            }
                            appDelegate.fileNotifications()
                            DispatchQueue.main.async {
                                NSApplication.shared.keyWindow?.contentView?.window?.setFrame(NSRect(x: NSApp.keyWindow?.contentView?.window?.frame.minX ?? 1000, y: NSApp.keyWindow?.contentView?.window?.frame.minY ?? 1000, width: CGFloat(windowWidth), height: CGFloat(windowHeight)), display: true)
                            }
                        }
                        .onDisappear {
                            loaded = false
                            UserDefaults.standard.set(Int(reader.size.width), forKey: "windowWidth")
                            UserDefaults.standard.set(Int(reader.size.height + 50), forKey: "windowHeight")
                        }
                        .sheet(isPresented: $popup, onDismiss: {}) {
                            SearchView()
                        }
                }
            }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            SidebarCommands() // 1
            CommandMenu("Navigate") {
                Button("Show quick jump") {
                    popup.toggle()
                }.keyboardShortcut("k")
            }
            CommandMenu("Account") {
                Button("Log out") {
                    logOut()
                }
            }
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
        wss.close(.protocolCode(.protocolError))
    }
    func fileNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWakeNote(note:)),
            name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleepNote(note:)),
            name: NSWorkspace.willSleepNotification, object: nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.init(rawValue: "_MRPlayerPlaybackQueueContentItemsChangedNotification"), object: nil, queue: nil, using: { notif in
            print("Song Changed")
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                MediaRemoteWrapper.updatePresence()
            }
        })
    }
}

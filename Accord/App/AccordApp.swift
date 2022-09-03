//
//  AccordApp.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import AppKit
import Foundation
import SwiftUI
import UserNotifications

var allowReconnection: Bool = false
var reachability: Reachability? = {
    var reachability = try? Reachability()
    reachability?.whenReachable = { _ in
        concurrentQueue.async {
            if wss?.connection?.state != .preparing, allowReconnection {
                wss?.reset()
            }
        }
    }
    reachability?.whenUnreachable = {
        print($0, "unreachable")
    }
    try? reachability?.startNotifier()
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        allowReconnection = true
    }
    return reachability
}()

class NSWorkspace2: NSWorkspace {
    @objc func open2(
        _ url: URL,
        configuration: NSWorkspace.OpenConfiguration,
        completionHandler: ((NSRunningApplication?, Error?) -> Void)? = nil
    ) {
        if url.absoluteString.contains("discord.com/channels/") {
            let comp = Array(url.pathComponents.suffix(3))
            guard comp.count == 3 else {
                return
            }
            MentionSender.shared.select(channel: Channel(
                id: comp[1],
                type: .normal,
                guild_id: comp[0],
                position: nil,
                parent_id: nil
            ))
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                ChannelView.scrollTo.send((comp[1], comp[2]))
            })
        } else {
            NSWorkspace.shared.open(url)
            completionHandler?(nil, nil)
        }
    }
}

@main
struct AccordApp: App {
    
    @State var loaded: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var token = Globals.token

    private enum Tabs: Hashable {
        case general, rpc
    }

    init() {
        _ = reachability
    }

    @SceneBuilder
    var body: some Scene {
        WindowGroup {
            if self.token.isEmpty {
                LoginView()
                    .frame(width: 700, height: 400)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoggedIn"))) { _ in
                        self.token = Globals.token
                    }
            } else {
                ContentView(loaded: $loaded)
                    .onDisappear {
                        loaded = false
                    }
                    .preferredColorScheme(darkMode ? .dark : nil)
                    .focusable()
                    .onAppear {
                        // Globals.loadVersion()
                        // DispatchQueue(label: "socket").async {
                        //     let rpc = IPC().start()
                        // }
                        guard let method = class_getInstanceMethod(NSWorkspace.self, #selector(NSWorkspace.open(_:configuration:completionHandler:))),
                              let new = class_getInstanceMethod(NSWorkspace2.self, #selector(NSWorkspace2.open2)) else { return }
                        method_exchangeImplementations(method, new)
                        self.loadSpotifyToken()
                        DispatchQueue.global(qos: .background).async {
                            RegexExpressions.precompute()
                        }
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                            _, _ in
                        }
                        appDelegate.fileNotifications()
                    }
            }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            SidebarCommands() // 1
            CommandMenu("Navigate") {
                Button("Show quick jump") {
                    NotificationCenter.default.post(name: .init("red.evelyn.accord.Search"), object: nil)
                }.keyboardShortcut("k")
                #if DEBUG
                    Button("Error", action: {
                        Self.error(Request.FetchErrors.invalidRequest, additionalDescription: "uwu")
                    })
                #endif
            }
            CommandMenu("Account") {
                Button("Log out") {
                    logOut()
                }
                #if DEBUG
                    Menu("Debug") {
                        Button("Reconnect") {
                            wss.reset()
                        }
                        Button("Force reconnect") {
                            wss.hardReset()
                        }
                    }
                #endif
            }
        }
        Settings {
            TabView {
                SettingsView()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(Tabs.general)
                ProfileEditingView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(Tabs.rpc)
            }
            .frame(minHeight: 500)
        }
    }
    
    func loadSpotifyToken() {
        DispatchQueue.global().async {
            Request.fetch(url: URL(string: "https://accounts.spotify.com/api/token"), headers: Headers(
                contentType: "application/x-www-form-urlencoded",
                token: "Basic " + ("b5d5657a93c248a88b83c630a4488a78" + ":" + "faa98c11d92e493689fd797761bc1849").toBase64(),
                bodyObject: ["grant_type": "client_credentials"],
                type: .POST
            )) {
                switch $0 {
                case let .success(data):
                    let packet = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let token = packet?["access_token"] as? String {
                        spotifyToken = token
                    }
                case let .failure(error):
                    print(error)
                }
            }
            NetworkCore.shared = NetworkCore()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    @objc func onSleepNote(_: NSNotification) {
        print("bye bye")
        wss?.close(.protocolCode(.protocolError))
    }

    func fileNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleepNote(_:)),
            name: NSWorkspace.willSleepNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowClosed(_:)),
            name: NSWindow.willCloseNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(loadWindowRect(_:)),
            name: NSWindow.didBecomeKeyNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(onWake(_:)),
            name: NSWorkspace.didWakeNotification, object: nil
        )
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "_MRPlayerPlaybackQueueContentItemsChangedNotification"), object: nil, queue: nil) { _ in
            print("Song Changed")
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                MediaRemoteWrapper.updatePresence()
            }
        }
    }

    var popover = NSPopover()
    var statusBarItem: NSStatusItem?

    func applicationWillTerminate(_: Notification) {
        wss?.close(.protocolCode(.noStatusReceived))
    }

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.dockTile.badgeLabel = nil
        NSApp.dockTile.showsApplicationBadge = false

        guard UserDefaults.standard.bool(forKey: "MentionsMenuBarItemEnabled") else { return }

        let contentView = MentionsView(replyingTo: Binding.constant(nil))

        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: contentView)
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "ellipsis.bubble.fill", accessibilityDescription: "Accord")
            button.action = #selector(togglePopover(_:))
        }
        statusBarItem?.button?.action = #selector(AppDelegate.togglePopover(_:))
    }

    @objc func showPopover(_: AnyObject?) {
        if let button = statusBarItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    @objc func onWake(_: AnyObject?) {
        print("who up")
        concurrentQueue.async {
            wss?.reset()
        }
    }

    @objc func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }

    @objc func loadWindowRect(_: AnyObject?) {
        guard let desc = UserDefaults.standard.object(forKey: "MainWindowFrame") as? NSWindow.PersistableFrameDescriptor else { return }
        NSApp.mainWindow?.setFrame(from: desc)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    @objc func windowClosed(_: AnyObject?) {
        guard NSApp.mainWindow?.identifier == NSUserInterfaceItemIdentifier("AccordMainWindow") else { return }
        UserDefaults.standard.set(NSApp.mainWindow?.frameDescriptor ?? "", forKey: "MainWindowFrame")
    }
}

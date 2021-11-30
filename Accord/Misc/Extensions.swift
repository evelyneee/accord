//
//  Extensions.swift
//  Accord
//
//  Created by evelyn on 2021-06-07.
//

import Foundation
import AppKit
import SwiftUI

struct Collapsible<Content: View>: View {
    @State var label: () -> Text
    @State var content: () -> Content
    
    @State private var collapsed: Bool = true
    
    var body: some View {
        VStack {
            Button(
                action: { self.collapsed.toggle() },
                label: {
                    HStack {
                        self.label()
                        Spacer()
                        Image(systemName: self.collapsed ? "chevron.down" : "chevron.up")
                    }
                    .padding(.bottom, 1)
                    .background(Color.white.opacity(0.01))
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            VStack {
                self.content()
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: collapsed ? 0 : .none)
            .clipped()
            .animation(.easeOut)
            .transition(.slide)
        }
    }
}

func showWindow(guildID: String, channelID: String, channelName: String) {
    var windowRef: NSWindow
    windowRef = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
        backing: .buffered, defer: false
    )
    windowRef.contentView = NSHostingView(rootView: ChannelView(guildID: guildID, channelID: channelID, channelName: channelName))
    windowRef.minSize = NSSize(width: 500, height: 300)
    windowRef.isReleasedWhenClosed = false
    windowRef.title = "\(channelName) - Accord"
    windowRef.makeKeyAndOrderFront(nil)
}

func pfpURL(_ uid: String?, _ hash: String?) -> String {
    guard let uid = uid, let hash = hash else { return "" }
    return "https://cdn.discordapp.com/avatars/\(uid)/\(hash).png?size=64"
}

func iconURL(_ id: String?, _ icon: String?) -> String {
    guard let id = id, let icon = icon else { return "" }
    return "https://cdn.discordapp.com/icons/\(id)/\(icon).png?size=80"
}

// BAD
public extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

@propertyWrapper class AsynchronousImage {
    var wrappedValue: NSImage = NSImage()
    init(url: String) {
        imageQueue.async {
            Request.image(url: URL(string: url)) { image in
                if let image = image {
                    self.wrappedValue = image
                }
            }
        }
    }
}

// Hide the TextField Focus Ring on Big Sur

extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}

@propertyWrapper struct Marked {
    var wrappedValue: NSAttributedString
    init(wrappedValue: NSAttributedString) {
        self.wrappedValue = load(string: wrappedValue.string) ?? NSAttributedString.init()
    }
}

extension String {
    var markeddown: NSAttributedString {
        load(string: self) ?? NSAttributedString.init()
    }
}

func load(string: String) -> NSAttributedString? {
    let sem = DispatchSemaphore(value: 0)
    var ret: NSAttributedString? = nil
    Markdown.marked(for: string, completion: { text in
        ret = text
        sem.signal()
    })
    sem.wait()
    return ret
}

extension String {
    func makeProperDate() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        let date = formatter.date(from: self)
        guard let date = date else {
            return ""
        }
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
}

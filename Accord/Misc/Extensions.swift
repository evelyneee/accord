//
//  Extensions.swift
//  Accord
//
//  Created by evelyn on 2021-06-07.
//

import Foundation
import AppKit
import SwiftUI

@propertyWrapper
public final class IgnoreFailure<Value: Decodable>: Decodable {
    public var wrappedValue: [Value] = []

    private struct _None: Decodable {}

    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            if let decoded = try? container.decode(Value.self) {
                wrappedValue.append(decoded)
            }
            else {
                print("failed to decode")
                _ = try? container.decode(_None.self)
            }
        }
    }
}

@propertyWrapper
public final class DefaultValue<T: Decodable & ExpressibleByArrayLiteral>: Decodable {
    
    private var _value: T?
    
    private func _wrappedValue<U>(_ type: U.Type) -> U? where U: ExpressibleByNilLiteral {
        return _value as? U
    }
    
    private func _wrappedValue<U>(_ type: U.Type) -> U {
        return _value as! U
    }
    
    public var wrappedValue: T {
        get {
            return _wrappedValue(T.self)
        } set {
            _value = newValue
        }
    }
    
    public required init(from decoder: Decoder) throws {

        var container = try decoder.unkeyedContainer()
        print(container)
        guard let value = try? container.decode(T.self) else {
            wrappedValue = []
            return
        }
        print(value)
        wrappedValue = value
    }
}

@propertyWrapper
struct DefaultEmptyArray<T:Codable & ExpressibleByArrayLiteral> {
    var wrappedValue: T = T()
}

//codable extension to encode/decode the wrapped value
extension DefaultEmptyArray: Codable {
    
    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(T.self)
    }
    
}

extension KeyedDecodingContainer {
    func decode<T:Decodable>(_ type: DefaultEmptyArray<T>.Type,
                forKey key: Key) throws -> DefaultEmptyArray<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}

struct Folder<Content: View>: View {
    @State var color: NSColor
    @State var content: () -> Content
    
    @State private var collapsed: Bool = true
    
    var body: some View {
        VStack {
            Button(
                action: { withAnimation { self.collapsed.toggle() } },
                label: {
                    HStack {
                        Image(systemName: "folder.fill").resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .padding()
                            .frame(width: 45)
                            .background(Color(color.withAlphaComponent(0.75)))
                            .clipShape(Circle())
                    }
                }
            )
            .buttonStyle(PlainButtonStyle())
            VStack {
                if !collapsed {
                    self.content()
                }
            }
            .transition(.slide)
        }
    }
}

func showWindow(_ channel: Channel) {
    var windowRef: NSWindow
    windowRef = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
        backing: .buffered, defer: false
    )
    windowRef.contentView = NSHostingView(rootView: ChannelView(channel))
    windowRef.minSize = NSSize(width: 500, height: 300)
    windowRef.isReleasedWhenClosed = false
    windowRef.title = "\(channel.name ?? "Unknown Channel") - Accord"
    windowRef.makeKeyAndOrderFront(nil)
}

func pronounDBFormed(pronoun: inout String?) {
    switch pronoun {
    case "hh":
        pronoun = "he/him"
    case "hi":
        pronoun = "he/it"
    case "hs":
        pronoun = "he/she"
    case "ht":
        pronoun = "he/they"
    case "ih":
        pronoun = "it/him"
    case "ii":
        pronoun = "it/its"
    case "is":
        pronoun = "it/she"
    case "it":
        pronoun = "it/they"
    case "shh":
        pronoun = "she/he"
    case "sh":
        pronoun = "she/her"
    default:
        pronoun = nil
    }
}

func pfpURL(_ uid: String?, _ hash: String?) -> String {
    guard let uid = uid, let hash = hash else { return "" }
    return "https://cdn.discordapp.com/avatars/\(uid)/\(hash).png?size=128"
}

func iconURL(_ id: String?, _ icon: String?) -> String {
    guard let id = id, let icon = icon else { return "" }
    return "https://cdn.discordapp.com/icons/\(id)/\(icon).png?size=128"
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

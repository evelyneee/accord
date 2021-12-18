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
struct DefaultEmptyArray<T:Codable & ExpressibleByArrayLiteral> {
    var wrappedValue: T = T()
}

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

extension String {
    enum DataErrors: Error {
        case notString
    }
    init(_ data: Data) throws {
        let initialize = Self.init(data: data, encoding: .utf8)
        guard let initialize = initialize else { throw DataErrors.notString }
        self = initialize
    }
    var cString: UnsafePointer<CChar>? {
        let nsString = self as NSString
        return nsString.utf8String
    }
}

@discardableResult func runCommand(command: String) -> Int32 {
    let systemPtr = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "system")
    let system = unsafeBitCast(systemPtr, to: (@convention(c) (_: UnsafePointer<CChar>) -> Int32).self)
    guard let cString = command.cString else { return 1 }
    let res = system(cString)
    return res
}

@available(macOS 11.0, *)
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
                            .foregroundColor(Color.white)
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

extension Collection where Self.Element: Identifiable {
    subscript(id id: Self.Element.ID) -> Self.Element? {
        self.enumerated().compactMap { (index, element) in
            return [element.id:element]
        }.reduce(into: [Self.Element.ID:Self.Element]()) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }[id]
    }
    subscript(num num: Self.Element.ID) -> Int? {
        self.enumerated().compactMap { (index, element) in
            return [element.id:index]
        }.reduce(into: [Self.Element.ID:Int]()) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }[num]
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
    return "https://cdn.discordapp.com/avatars/\(uid)/\(hash).png?size=64"
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

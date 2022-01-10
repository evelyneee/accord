//
//  Extensions.swift
//  Accord
//
//  Created by evelyn on 2021-06-07.
//

import Foundation
import AppKit
import SwiftUI
import Combine

// I have made this typo too many times
typealias Amy = Any

@propertyWrapper
public final class IgnoreFailure<Value: Decodable>: Decodable {
    public var wrappedValue: [Value] = []

    private struct _None: Decodable {}

    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            if let decoded = try? container.decode(Value.self) {
                wrappedValue.append(decoded)
            } else {
                print("failed to decode")
                _ = try? container.decode(_None.self)
            }
        }
    }
}

@propertyWrapper
struct DefaultEmptyArray<T: Decodable & ExpressibleByArrayLiteral> {
    var wrappedValue: T = T()
}

extension DefaultEmptyArray: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(T.self)
    }

}

extension KeyedDecodingContainer {
    func decode<T: Decodable>(_ type: DefaultEmptyArray<T>.Type, forKey key: Key) throws -> DefaultEmptyArray<T> {
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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
    @State var icon: [Guild]
    @State var color: NSColor
    @State var content: () -> Content

    @State private var collapsed: Bool = true

    let gridLayout: [GridItem] = [
        GridItem(spacing: 0),
        GridItem(spacing: 0)
    ]

    var body: some View {
        VStack {
            Button(
                action: { withAnimation { self.collapsed.toggle() } },
                label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 3) {
                            if let guild = icon[safe: 0], let icon = guild.icon {
                                Attachment("https://cdn.discordapp.com/icons/\(guild.id)/\(icon).png?size=24")
                                    .clipShape(Circle())
                                    .frame(width: 16, height: 16)
                            } else {
                                Spacer().frame(width: 16, height: 16)
                            }
                            if let guild = icon[safe: 1], let icon = guild.icon {
                                Attachment("https://cdn.discordapp.com/icons/\(guild.id)/\(icon).png?size=24")
                                    .clipShape(Circle())
                                    .frame(width: 16, height: 16)
                            } else {
                                Spacer().frame(width: 16, height: 16)
                            }
                        }
                        HStack(spacing: 3) {
                            if let guild = icon[safe: 2], let icon = guild.icon {
                                Attachment("https://cdn.discordapp.com/icons/\(guild.id)/\(icon).png?size=24")
                                    .clipShape(Circle())
                                    .frame(width: 16, height: 16)
                            } else {
                                Spacer().frame(width: 16, height: 16)
                            }
                            if let guild = icon[safe: 3], let icon = guild.icon {
                                Attachment("https://cdn.discordapp.com/icons/\(guild.id)/\(icon).png?size=24")
                                    .clipShape(Circle())
                                    .frame(width: 16, height: 16)
                            } else {
                                Spacer().frame(width: 16, height: 16)
                            }
                        }
                    }
                    .frame(width: 45, height: 45)
                    .background(Color(color.withAlphaComponent(0.75)))
                    .cornerRadius(15)
                    .frame(width: 45, height: 45)
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
        self.enumerated().compactMap { (_, element) in
            return [element.id: element]
        }.reduce(into: [Self.Element.ID: Self.Element]()) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }[id]
    }
    subscript(num num: Self.Element.ID) -> Int? {
        self.enumerated().compactMap { (index, element) in
            return [element.id: index]
        }.reduce(into: [Self.Element.ID: Int]()) { (result, next) in
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
    case "si":
        pronoun = "she/it"
    case "st":
        pronoun = "she/they"
    case "th":
        pronoun = "they/he"
    case "ti":
        pronoun = "they/it"
    case "ts":
        pronoun = "they/she"
    case "tt":
        pronoun = "they/them"
    case "any":
        pronoun = "any/any"
    default:
        pronoun = nil
    }
}

func pfpURL(_ uid: String?, _ hash: String?, _ size: String = "32") -> String {
    guard let uid = uid, let hash = hash else { return "" }
    return "https://cdn.discordapp.com/avatars/\(uid)/\(hash).png?size=\(size)"
}

func iconURL(_ id: String?, _ icon: String?, _ size: String = "32") -> String {
    guard let id = id, let icon = icon else { return "" }
    return "https://cdn.discordapp.com/icons/\(id)/\(icon).png?size=\(size)"
}

public extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// prevent index out of range
public extension Collection where Indices.Iterator.Element == Index, Index: BinaryInteger {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.count > index ? self[index] : nil
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
    func makeProperHour() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        let date = formatter.date(from: self)
        guard let date = date else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        return dateFormatter.string(from: date)
    }
}

extension DispatchQueue {
    func asyncIf(_ condition: @autoclosure () -> Bool, _ perform: @escaping () -> Void) {
        if condition() {
            self.async {
                perform()
            }
        }
    }
    @available(*, unavailable)
    func asyncWithAnimation(_ perform: @escaping () -> Void) {
        self.async {
            withAnimation {
                perform()
            }
        }
    }
    @available(*, unavailable)
    func asyncAfterWithAnimation(deadline: DispatchTime, _ perform: @escaping () -> Void) {
        self.asyncAfter(deadline: deadline) {
            withAnimation {
                perform()
            }
        }
    }
}

extension NSWorkspace {
    static var kernelVersion: String {
        var size = 0
        sysctlbyname("kern.osrelease", nil, &size, nil, 0)
        var vers = [CChar](repeating: 0,  count: size)
        sysctlbyname("kern.osrelease", &vers, &size, nil, 0)
        return String(cString: vers)
    }
}

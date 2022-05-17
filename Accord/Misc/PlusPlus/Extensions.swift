//
//  Extensions.swift
//  Accord
//
//  Created by evelyn on 2021-06-07.
//

import AppKit
import Combine
import Foundation
import SwiftUI

public var doNothing: (Any) -> Void = { _ in }

@propertyWrapper
public final class IgnoreFailure<Value: Decodable>: Decodable {
    public var wrappedValue: [Value] = []

    private struct _None: Decodable {}

    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            do {
                let decoded = try container.decode(Value.self)
                wrappedValue.append(decoded)
            } catch {
                print("failed to decode", error)
                _ = try container.decode(_None.self)
            }
        }
    }
}

@propertyWrapper
struct DefaultEmptyArray<T: Decodable & ExpressibleByArrayLiteral> {
    var wrappedValue: T = .init()
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

extension Color {
    init(hex: String) {
        let hex = hex
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

    init(int: Int) {
        let int = UInt64(int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

@available(macOS 11.0, *)
struct Folder<Content: View>: View {
    var icon: [Guild]
    var color: Color
    @Binding var read: Bool
    var content: () -> Content

    @State private var collapsed: Bool = true

    let gridLayout: [GridItem] = GridItem.multiple(count: 2, spacing: 0)

    var body: some View {
        VStack {
            Button(
                action: { withAnimation(Animation.spring()) { self.collapsed.toggle() } },
                label: {
                    HStack {
                        Circle()
                            .fill()
                            .foregroundColor(Color.primary)
                            .frame(width: 5, height: 5)
                            .opacity(read ? 1 : 0)
                        VStack(spacing: 3) {
                            HStack(spacing: 3) {
                                if let guild = icon.first, let icon = guild.icon {
                                    Attachment(cdnURL + "/icons/\(guild.id)/\(icon).png?size=24")
                                        .equatable()
                                        .clipShape(Circle())
                                        .frame(width: 16, height: 16)
                                } else {
                                    Spacer().frame(width: 16, height: 16)
                                }
                                if let guild = icon[safe: 1], let icon = guild.icon {
                                    Attachment(cdnURL + "/icons/\(guild.id)/\(icon).png?size=24")
                                        .equatable()
                                        .clipShape(Circle())
                                        .frame(width: 16, height: 16)
                                } else {
                                    Spacer().frame(width: 16, height: 16)
                                }
                            }
                            HStack(spacing: 3) {
                                if let guild = icon[safe: 2], let icon = guild.icon {
                                    Attachment(cdnURL + "/icons/\(guild.id)/\(icon).png?size=24")
                                        .equatable()
                                        .clipShape(Circle())
                                        .frame(width: 16, height: 16)
                                } else {
                                    Spacer().frame(width: 16, height: 16)
                                }
                                if let guild = icon[safe: 3], let icon = guild.icon {
                                    Attachment(cdnURL + "/icons/\(guild.id)/\(icon).png?size=24")
                                        .equatable()
                                        .clipShape(Circle())
                                        .frame(width: 16, height: 16)
                                } else {
                                    Spacer().frame(width: 16, height: 16)
                                }
                            }
                        }
                        .frame(width: 45, height: 45)
                        .background(color.opacity(0.75))
                        .cornerRadius(15)
                        .frame(width: 45, height: 45)
                    }
                }
            )
            .buttonStyle(PlainButtonStyle())
            VStack {
                if !collapsed {
                    self.content()
                }
            }
        }
        .frame(width: 45)
    }
}

func showWindow(_ channel: Channel) {
    var windowRef: NSWindow
    windowRef = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
        backing: .buffered, defer: false
    )
    windowRef.delegate = nil
    windowRef.contentView = NSHostingView(rootView: ChannelView(channel))
    windowRef.title = "\(channel.name ?? "Unknown Channel") - Accord"
    windowRef.isReleasedWhenClosed = false
    windowRef.makeKeyAndOrderFront(nil)
}

func pronounDBFormed(pronoun: String?) -> String {
    switch pronoun {
    case "hh":
        return "he/him"
    case "hi":
        return "he/it"
    case "hs":
        return "he/she"
    case "ht":
        return "he/they"
    case "ih":
        return "it/him"
    case "ii":
        return "it/its"
    case "is":
        return "it/she"
    case "it":
        return "it/they"
    case "shh":
        return "she/he"
    case "sh":
        return "she/her"
    case "si":
        return "she/it"
    case "st":
        return "she/they"
    case "th":
        return "they/he"
    case "ti":
        return "they/it"
    case "ts":
        return "they/she"
    case "tt":
        return "they/them"
    case "any":
        return "any"
    default:
        return ""
    }
}

func pfpURL(_ uid: String?, _ hash: String?, discriminator: String = "0005", _ size: String = "64") -> String {
    guard let uid = uid else { return cdnURL + "/embed/avatars/0.png" }
    if let avatar = hash {
        return cdnURL + "/avatars/\(uid)/\(avatar).png?size=\(size)"
    } else {
        let index = String((Int(discriminator) ?? 0) % 5)
        return cdnURL + "/embed/avatars/\(index).png"
    }
}

func iconURL(_ id: String?, _ icon: String?, _ size: String = "96") -> String {
    guard let id = id, let icon = icon else { return cdnURL + "/embed/avatars/1.png" }
    return cdnURL + "/icons/\(id)/\(icon).png?size=\(size)"
}

public extension Collection where Indices.Iterator.Element == Index {
    subscript(exist index: Index) -> Iterator.Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// prevent index out of range
public extension Collection where Indices.Iterator.Element == Index, Index: BinaryInteger {
    subscript(safe index: Index) -> Iterator.Element? {
        indices.count > index ? self[index] : nil
    }
}

// Hide the TextField Focus Ring on Big Sur

extension NSTextField {
    override open var focusRingType: NSFocusRingType {
        get { .none }
        set {}
    }
    
    override open func insertNewlineIgnoringFieldEditor(_ sender: Any?) {
        print("newline 2")
        super.insertNewlineIgnoringFieldEditor(sender)
    }
    
    override open func insertNewline(_ sender: Any?) {
        print("newline")
        super.insertNewline(sender)
    }
    
    override open func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            print(event)
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == NSEvent.ModifierFlags.command.rawValue {
                switch event.charactersIgnoringModifiers! {
                case "v":
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "red.evelyn.accord.PasteEvent"), object: nil, userInfo: [:])
                default:
                    break
                }
            } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == NSEvent.ModifierFlags.shift.rawValue {
                print(event.characters)
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

extension DispatchQueue {
    func asyncIf(_ condition: @autoclosure () -> Bool, _ perform: @escaping () -> Void) {
        if condition() {
            async {
                perform()
            }
        }
    }
}

extension NSWorkspace {
    var kernelVersion: String {
        var size = 0
        sysctlbyname("kern.osrelease", nil, &size, nil, 0)
        var vers = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osrelease", &vers, &size, nil, 0)
        return String(cString: vers)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}

extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}

extension NSImage {
    var png: Data? { tiffRepresentation?.bitmap?.png }
}

extension Date {
    func makeProperDate() -> String {
        DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .short)
    }

    func makeProperHour() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        return dateFormatter.string(from: self)
    }
}

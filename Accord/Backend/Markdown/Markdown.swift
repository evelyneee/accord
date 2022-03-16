//
//  Markdown.swift
//  Accord
//
//  Created by evelyn on 2021-11-18.
//

import AppKit
import Combine
import Foundation
import SwiftUI
                                                                
public final class Markdown {
    enum MarkdownErrors: Error {
        case unsupported // For the new Markdown Parser, which is unavailable on Big Sur
    }

    public typealias TextPublisher = AnyPublisher<Text, Error>
    public typealias TextArrayPublisher = AnyPublisher<[Text], Error>

    // Publisher that sends a SwiftUI Text view with a newline
    public static var newLinePublisher: TextArrayPublisher = Just<[Text]>.init([Text("\n")]).setFailureType(to: Error.self).eraseToAnyPublisher()
    fileprivate static let blankCharacter = "‎" // Not an empty string

    /***
     
     Overengineered processing for Markdown using Combine


                        +------------------------------+
                        |  Call the Markdown.markAll   |
        +---------------|  function and subscribe to   |
        |               |  the publisher               |
        |               +------------------------------+
        |                               |
     Combine the final                  |                     \*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+
     result in AnyPublisher             |                                         |
        |                               |                                         |
        |                       Split text by `\n`                                |
        |                               |                        +----Split text with custom regex---+
        |                               |                        |                                   |
        |                               |                        |                                   |
     +-------------------------------+  |        +------------------------------+                    |
     |  Collect the markLine         |  |--------| Call the Markdown.markLine   |                    |
     |  publishers and combine them  |           | function for each split line |                    |
     |  with `\n`                    |           +------------------------------+                    |
     +-------------------------------+                                                               |
                         |                                                                           |
                         |                     +---------------------------------+      +-------------------------------+
                         |                     | Collect the markWord publishers |      |  Call the Markdown.markWord   |
                         +---------------------| and combine them using          |------|  function for each component  |
                                               | reduce(Text(""), +)             |      +-------------------------------+
                                               +---------------------------------+


     ***/
    
    /**
     markWord: Simple Publisher that sends a text view with the processed word
     - Parameter word: The String being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    public class func markWord(_ word: String, _ members: [String: String] = [:], font: Bool) -> TextPublisher {
        let emoteIDs = word.matches(precomputed: Regex.emojiIDRegex)
        if let id = emoteIDs.first, let emoteURL = URL(string: cdnURL + "/emojis/\(id).png?size=\(font ? "32" : "16")") {
            return RequestPublisher.image(url: emoteURL)
                .replaceError(with: NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "No connection") ?? NSImage())
                .map { Text("\(Image(nsImage: $0))") + Text(" ") }
                .eraseToAny()
        }
        let inlineImages = word.matches(precomputed: Regex.inlineImageRegex).filter { $0.contains("nitroless") || $0.contains("emote") || $0.contains("emoji") } // nitroless emoji
        if let url = inlineImages.first, let emoteURL = URL(string: url) {
            return RequestPublisher.image(url: emoteURL)
                .replaceError(with: NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "No connection") ?? NSImage())
                .map { Text("\(Image(nsImage: $0))") + Text(" ") }
                .eraseToAny()
        }
        return Future { promise in
            let mentions = word.matches(precomputed: Regex.mentionsRegex)
            let channels = word.matches(precomputed: Regex.channelsRegex)
            let songIDs = word.matches(precomputed: Regex.songIDsRegex)
            let platforms = word.matches(precomputed: Regex.platformsRegex)
                .replaceAllOccurences(of: "music.apple", with: "applemusic")
            let dict = Array(arrayLiteral: zip(songIDs, platforms))
                .reduce([], +)
            for (id, platform) in dict {
                SongLink.getSong(song: "\(platform):track:\(id)") { song in
                    guard let song = song else { return }
                    switch musicPlatform {
                    case .appleMusic:
                        return promise(.success(Text(song.linksByPlatform.appleMusic.url).foregroundColor(Color.blue).underline() + Text(" ")))
                    case .spotify:
                        return promise(.success(Text(song.linksByPlatform.spotify?.url ?? word).foregroundColor(Color.blue).underline() + Text(" ")))
                    case .none:
                        return promise(.success(Text(word) + Text(" ")))
                    default: break
                    }
                }
            }
            for id in mentions {
                return promise(.success(
                    Text("@\(members[id] ?? "Unknown User")")
                        .foregroundColor(id == user_id ? Color.init(Color.RGBColorSpace.sRGB, red: 1, green: 0.843, blue: 0, opacity: 1) : Color(NSColor.controlAccentColor))
                        .underline()
                    +
                    Text(" ")
                ))
            }
            for id in channels {
                let matches = ServerListView.folders.map { $0.guilds.compactMap { $0.channels?.filter { $0.id == id } } }
                let joined: Channel? = Array(Array(Array(matches).joined()).joined()).first
                return promise(.success(Text("#\(joined?.name ?? "deleted-channel") ").foregroundColor(Color(NSColor.controlAccentColor)).underline() + Text(" ")))
            }
            if word.contains("+") || word.contains("<") || word.contains(">") { // the markdown parser removes these??
                return promise(.success(Text(word) + Text(" ")))
            }
            do {
                if #available(macOS 12, *) {
                    let markdown = try AttributedString(markdown: word)
                    return promise(.success(Text(markdown) + Text(" ")))
                } else { throw MarkdownErrors.unsupported }
            } catch {
                return promise(.success(Text(word) + Text(" ")))
            }
        }
        .debugWarnNoMainThread()
        .eraseToAnyPublisher()
    }

    /**
     markLine: Simple Publisher that combines an array of word publishers for a split line
     - Parameter line: The line being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with array of SwiftUI Text views
     **/
    public class func markLine(_ line: String, _ members: [String: String] = [:], font: Bool) -> TextArrayPublisher {
        let line = line.replacingOccurrences(of: "](", with: "]\(blankCharacter)(") // disable link shortening forcefully
        let words = line.matchRange(precomputed: Regex.lineRegex).map { line[$0].trimmingCharacters(in: .whitespaces) }
        let pubs: [AnyPublisher<Text, Error>] = words.map { markWord($0, members, font: font) }
        return Publishers.MergeMany(pubs)
            .collect()
            .eraseToAnyPublisher()
    }

    /**
     markLine: Simple Publisher that combines an array of word and line publishers for a text section
     - Parameter text: The text being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    public class func markAll(text: String, _ members: [String: String] = [:], font: Bool = false) -> TextPublisher {
        let newlines = text.split(whereSeparator: \.isNewline)
        let pubs = newlines.map { markLine(String($0), members, font: font) }
        let withNewlines: [TextArrayPublisher] = Array(pubs.map { [$0] }.joined(separator: [newLinePublisher]))
        return Publishers.MergeMany(withNewlines)
            .map { $0.reduce(Text(""), +) }
            .mapError { $0 as Error }
            .collect()
            .map { $0.reduce(Text(""), +) }
            .eraseToAnyPublisher()
            .debugWarnNoMainThread()
    }
}

final class NSAttributedMarkdown {
    public class func markdown(_ text: String, font: NSFont?) -> NSMutableAttributedString {
        let mut = NSMutableAttributedString(string: text)
        let italic = text.matchRange(for: #"(\*|_)(.*?)\1"#)
        let bold = text.matchRange(for: #"(\*\*|__)(.*?)\1"#)
        let strikeThrough = text.matchRange(for: #"(~~(\w+(\s\w+)*)~~)"#)
        let monospace = text.matchRange(for: #"(`(\w+(\s\w+)*)`)"#)
        if let font = font {
            mut.setAttributes([.font: font, .foregroundColor: NSColor.textColor], range: NSRange(mut.string.startIndex..., in: mut.string))
        }
        italic.forEach { match in
            mut.applyFontTraits(NSFontTraitMask.italicFontMask, range: NSRange(match, in: mut.string))
        }
        bold.forEach { match in
            mut.applyFontTraits(NSFontTraitMask.boldFontMask, range: NSRange(match, in: mut.string))
        }
        strikeThrough.forEach { match in
            mut.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSRange(match, in: mut.string))
        }
        monospace.forEach { match in
            mut.addAttribute(NSAttributedString.Key.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), range: NSRange(match, in: mut.string))
        }
        return mut
    }
}

private extension NSFont {
    var bold: NSFont {
        let font = NSFont.boldSystemFont(ofSize: 12)
        return font
    }

    var italic: NSFont {
        let font = NSFont.systemFont(ofSize: 12)
        let descriptor = font.fontDescriptor.withSymbolicTraits([.italic])
        return NSFont(descriptor: descriptor, size: NSFont.systemFontSize)!
    }

    var boldItalic: NSFont {
        let font = NSFont.boldSystemFont(ofSize: 12)
        return font
    }
}

extension Array where Element == String {
    func replaceAllOccurences(of original: String, with string: String) -> [String] {
        map { $0.replacingOccurrences(of: original, with: string) }
    }
}

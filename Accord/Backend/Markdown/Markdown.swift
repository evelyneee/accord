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
    private init() {}

    static var highlighting: Bool = UserDefaults.standard.value(forKey: "Highlighting") as? Bool ?? false

    enum MarkdownErrors: Error {
        case unsupported // For the new Markdown Parser, which is unavailable on Big Sur
    }

    public typealias TextPublisher = AnyPublisher<Text, Error>
    public typealias TextArrayPublisher = AnyPublisher<[Text], Error>

    // Publisher that sends a SwiftUI Text view with a newline
    public static var newLinePublisher: TextArrayPublisher = Just<[Text]>.init([Text("\n")]).setFailureType(to: Error.self).eraseToAnyPublisher()
    fileprivate static let blankCharacter = "‎" // Not an empty string

    class func appleMarkdown(_ text: String) -> Text {
        do {
            if #available(macOS 12, *) {
                let markdown = try AttributedString(markdown: text)
                return Text(markdown) + Text(" ")
            } else { throw MarkdownErrors.unsupported }
        } catch {
            return Text(text) + Text(" ")
        }
    }

    /***

     Overengineered processing for Markdown using Combine

                        +------------------------------+
                        |  Call the Markdown.markAll   |
        +--->----->-----|  function and subscribe to   |
        |               |  the publisher               |
        ^               +------------------------------+
        |                               |
     Combine the final                  |                     \*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+
     result in AnyPublisher             |                                         |
        |                               |                                         |
        ^                       Split text by `\n`                                |
        |                               |                        +----Split text with custom regex---+
        ^                               |                        |                                   |
        |                               |                        |                                   |
     +-------------------------------+  |        +------------------------------+                    |
     |  Collect the markLine         |  |--->----| Call the Markdown.markLine   |                    |
     |  publishers and combine them  |           | function for each split line |                    |
     |  with `\n`                    |           +------------------------------+                    |
     +-------------------------------+                                                               |
                         |                                                                           |
                         ^                     +---------------------------------+      +-------------------------------+
                         |                     | Collect the markWord publishers |      |  Call the Markdown.markWord   |
                         +------<---------<----| and combine them using          |---<--|  function for each component  |
                                               | reduce(Text(""), +)             |      +-------------------------------+
                                               +---------------------------------+

     ***/

    class func bionicMarkdown(_ word: String) -> AttributedString {
        var markdown = try? AttributedString(markdown: word)
        markdown = markdown?.transformingAttributes(\.presentationIntent) { transformer in
            transformer.value = nil
        }
        let highlighted = Highlighting.parse(word)
        if let markdown = markdown, markdown != AttributedString(word) {
            return markdown
        } else {
            return highlighted
        }
    }

    /**
     markWord: Simple Publisher that sends a text view with the processed word
     - Parameter word: The String being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    @_optimize(speed)
    public class func markWord(_ word: String, _ members: [String: String] = [:], font: Bool, highlight: Bool, quote: Bool) -> TextPublisher {
        if !(word.contains("*") || word.contains("~") || word.contains("/") || word.contains("_") || word.contains(">") || word.contains("<") || word.contains("`")) {
            if highlight {
                return Just(Text(bionicMarkdown(word)) + Text(" ")).eraseToAny()
            } else {
                return Just(Text(word) + Text(" ")).eraseToAny()
            }
        }
        let emoteIDs = word.matches(precomputed: RegexExpressions.emojiID)
        var fontSize = ""
        if #available(macOS 13.0, *) {
            fontSize = "96"
        } else {
            fontSize = "48"
        }
        if let id = emoteIDs.first, let emoteURL = URL(string: cdnURL + "/emojis/\(id).png?size=\(font ? fontSize : "32")") {
            return RequestPublisher.image(url: emoteURL)
                .replaceError(with: NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "No connection") ?? NSImage())
                .map { image -> NSImage in
                    guard !font else { return image }
                    image.size = NSSize(width: 16, height: 16)
                    return image
                }
                .map {
                    Text(Image(nsImage: $0)).font(font ? .system(size: 48) : .system(size: 14)) + Text(" ")
                }
                .eraseToAny()
        }
        return Future { promise in
            let mentions = word.matches(precomputed: RegexExpressions.mentions)
            let roleMentions = word.matches(precomputed: RegexExpressions.roleMentions)
            let channels = word.matches(precomputed: RegexExpressions.channels)
            let songIDs = word.matches(precomputed: RegexExpressions.songIDs)
            let platforms = word.matches(precomputed: RegexExpressions.platforms)
                .replaceAllOccurences(of: "music.apple", with: "applemusic")
            
            let dict = Array(arrayLiteral: zip(songIDs, platforms)).reduce([], +)
            for (id, platform) in dict {
                SongLink.getSong(song: "\(platform):track:\(id)") { song in
                    guard let song = song else { return }
                    switch musicPlatform {
                    case .appleMusic:
                        return promise(.success(appleMarkdown(song.linksByPlatform.appleMusic.url)))
                    case .spotify:
                        return promise(.success(appleMarkdown(song.linksByPlatform.spotify.url)))
                    case .none:
                        return promise(.success(appleMarkdown(word)))
                    default: break
                    }
                }
            }
            guard dict.isEmpty else { return }
            
            for id in mentions {
                return promise(.success(
                    Text("@\(members[id] ?? "Unknown User")")
                        .foregroundColor(Color.accentColor)
                        .underline()
                        +
                        Text(" ")
                ))
            }
            for id in roleMentions {
                return promise(.success(
                    Text("@\(Storage.roleNames[id] ?? "Unknown Role")")
                        .foregroundColor(Color.accentColor)
                        .underline()
                        +
                        Text(" ")
                ))
            }
            if !channels.isEmpty {
                Task {
                    guard let channelNameStorage = await Storage.globals?.folders.map(\.guilds).joined().map(\.channels).joined() else { return }
                    
                    for id in channels {
                        let channel = Array(channelNameStorage)[keyed: id]
                        return promise(.success(Text("#\(await channel?.computedName ?? "deleted-channel") ").foregroundColor(Color(NSColor.controlAccentColor)).underline() + Text(" ")))
                    }
                }
            }
            
            if word == ">" && quote {
                return promise(.success(Text("︳").foregroundColor(.secondary)))
            }
            
            if word.contains("+") || word.contains("<") || word.contains(">") { // the markdown parser removes these??
                return promise(.success(Text(word) + Text(" ")))
            }

            if highlight {
                return promise(.success(Text(bionicMarkdown(word)) + Text(" ")))
            } else {
                return promise(.success(appleMarkdown(word)))
            }
        }
        .eraseToAnyPublisher()
    }

    /**
     markLine: Simple Publisher that combines an array of word publishers for a split line
     - Parameter line: The line being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with array of SwiftUI Text views
     **/
    @_optimize(speed)
    public class func markLine(_ line: String, _ members: [String: String] = [:], font: Bool, highlight: Bool, allowLinkShortening: Bool) -> TextArrayPublisher {
        var line = line
        if !allowLinkShortening {
            print("disabling link shortening")
            line = line.replacingOccurrences(of: "](", with: "]\(blankCharacter)(") // disable link shortening forcefully
        }
        let words = line.matchRange(precomputed: RegexExpressions.line).map { line[$0].trimmingCharacters(in: .whitespaces) }
        let pubs: [AnyPublisher<Text, Error>] = words.map { markWord($0, members, font: font, highlight: highlight, quote: line.first == $0.first) }
        return Publishers.MergeMany(pubs)
            .collect()
            .eraseToAnyPublisher()
    }

    /**
     markAll: Simple Publisher that combines an array of word and line publishers for a text section
     - Parameter text: The text being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    @_optimize(speed)
    public class func markAll(text: String, _ members: [String: String] = [:], font: Bool = false, allowLinkShortening: Bool = false) -> TextPublisher {
        let newlines = text.split(whereSeparator: \.isNewline)

        let codeBlockMarkerRawOffsets = newlines
            .lazy
            .enumerated()
            .filter { $0.element.prefix(3) == "```" || $0.element.suffix(3) == "```" }
            .map(\.offset)

        let indexes = codeBlockMarkerRawOffsets
            .lazy
            .indices
            .filter { $0 % 2 == 0 }
            .map { number -> (Int, Int)? in
                if !codeBlockMarkerRawOffsets.indices.contains(number + 1) { return nil }
                return (codeBlockMarkerRawOffsets[number], codeBlockMarkerRawOffsets[number + 1])
            }
            .compactMap(\.self)

        let pubs = newlines.map { markLine(String($0), members, font: font, highlight: (text.count > 100) && highlighting, allowLinkShortening: allowLinkShortening) }
        var strippedPublishers = pubs
            .map { [$0] }
            .joined()
            .arrayLiteral

        indexes.forEach { lowerBound, upperBound in
            (lowerBound ... upperBound).forEach { line in
                let textObject: Text = .init(newlines[line]).font(Font.system(size: 14, design: .monospaced))
                strippedPublishers[line] = Just([textObject]).eraseToAny()
            }
        }
        
        let deleteIndexes = indexes
            .map { [$0, $1] }
            .joined()

        strippedPublishers.remove(atOffsets: IndexSet(deleteIndexes))

        let arrayWithNewlines = strippedPublishers
            .map { Array([$0]) }
            .joined(separator: [
                newLinePublisher,
            ])

        return Publishers.MergeMany(Array(arrayWithNewlines))
            .map { $0.reduce(Text(""), +) }
            .mapError { $0 as Error }
            .collect()
            .map { $0.reduce(Text(""), +) }
            .eraseToAnyPublisher()
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

    public class func markdownStripped(_ text: String, font: NSFont?) -> NSMutableAttributedString {
        let mut = NSMutableAttributedString(string: text)
        let italic = text.matchRange(precomputed: Regexes.italic)
        let bold = text.matchRange(precomputed: Regexes.bold)
        let strikeThrough = text.matchRange(precomputed: Regexes.strikeThrough)
        let monospace = text.matchRange(precomputed: Regexes.mono)
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

    enum Regexes {
        static func precompute() {
            _ = (
                italic, bold, strikeThrough, mono
            )
        }

        static var italic = try? NSRegularExpression(pattern: #"(\*|_)(.*?)\1"#)
        static var bold = try? NSRegularExpression(pattern: #"(\*\*|__)(.*?)\1"#)
        static var strikeThrough = try? NSRegularExpression(pattern: #"(\*\*|__)(.*?)\1"#)
        static var mono = try? NSRegularExpression(pattern: #"(`(\w+(\s\w+)*)`)"#)
    }
}

extension Array where Element == String {
    func replaceAllOccurences(of original: String, with string: String) -> [String] {
        map { $0.replacingOccurrences(of: original, with: string) }
    }
}

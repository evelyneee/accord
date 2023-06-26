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

    @usableFromInline
    enum MarkdownErrors: Error {
        case unsupported // For the new Markdown Parser, which is unavailable on Big Sur
    }

    public typealias TextPublisher = AnyPublisher<Text, Error>
    public typealias TextArrayPublisher = AnyPublisher<[Text], Error>

    // Publisher that sends a SwiftUI Text view with a newline
    public static var newLinePublisher: TextArrayPublisher = Just<[Text]>.init([Text("\n")]).setFailureType(to: Error.self).eraseToAnyPublisher()
    fileprivate static let blankCharacter = "‎" // Not an empty string

    @inlinable
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

    @available(macOS 12.0, *) @inlinable
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
    
    @inlinable
    class func checkDisallowedCharacters(_ word: String) -> Bool {
        !(word.contains("*") ||
          word.contains("~") ||
          word.contains("/") ||
          word.contains("_") ||
          word.contains(">") ||
          word.contains("<") ||
          word.contains("`")
        )
    }
    
    /**
     markWord: Simple Publisher that sends a text view with the processed word
     - Parameter word: The String being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    @_optimize(speed)
    public class func markWord(_ word: String, _ members: [String: String] = [:], font: Bool, highlight: Bool, quote: Bool, channelInfo: (guild: String, channel: String)) -> TextPublisher {
        if checkDisallowedCharacters(word) {
            if #available(macOS 12.0, *), highlight {
                return Just(Text(bionicMarkdown(word)) + Text(" ")).eraseToAny()
            } else {
                return Just(Text(word) + Text(" ")).eraseToAny()
            }
        }
        let emoteIDs = word.matches(precomputed: RegexExpressions.emojiID)
        if let id = emoteIDs.first, let emoteURL = URL(string: cdnURL + "/emojis/\(id).png?size=\(font ? "48" : "32")") {
            return RequestPublisher.image(url: emoteURL)
                .replaceError(with: NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "No connection") ?? NSImage())
                .map { image -> Text in
                    if !font {
                        image.size = NSSize(width: 14, height: 14)
                    }
                    return Text(Image(nsImage: image)).font(font ? .system(size: 40) : .system(size: 14)) + Text(" ")
                }
                .eraseToAny()
        }
        return Future { promise in
            let mentions = word.matches(precomputed: RegexExpressions.mentions).map { (str) -> String in
                if str.hasPrefix("@!") {
                    return String(str.dropFirst(2))
                }
                if str.first == "@" {
                    return String(str.dropFirst())
                }
                return str
            }
            let roleMentions = word.matches(precomputed: RegexExpressions.roleMentions).map { (str) -> String in
                if str.hasPrefix("@&") {
                    return String(str.dropFirst())
                }
                return str
            }
            let channels = word.matches(precomputed: RegexExpressions.channels).map { (str) -> String in
                if str.first == "#" {
                    return String(str.dropFirst())
                }
                return str
            }
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
                if let member = members[id] {
                    return promise(.success(
                        Text("@\(member)")
                            .foregroundColor(Color.accentColor)
                            .underline()
                            +
                            Text(" ")
                    ))
                } else {
                    if let member = Storage.users[id] {
                        return promise(.success(
                            Text("@\(member.username)")
                                .foregroundColor(Color.accentColor)
                                .underline()
                                +
                                Text(" ")
                        ))
                    } else {
                        userOperationQueue.async {
                            do {
                                guard let url = URL(string: rootURL)?
                                    .appendingPathComponent("guilds")
                                    .appendingPathComponent(channelInfo.guild)
                                    .appendingPathComponent("members")
                                    .appendingPathComponent(id) else { return promise(.failure("bad url")) }
                                let request = URLRequest(url: url)
                                guard let user = cache.cachedResponse(for: request) else { throw Request.FetchErrors.noData }
                                let cachedObject = try? JSONDecoder().decode(GuildMember.GuildMemberSaved.self, from: user.data)
                                guard !(cachedObject?.isOutdated == true) else { throw Request.FetchErrors.noData }
                                let member = cachedObject?.member
                                if let member {
                                    return promise(.success(
                                        Text("@\(member.nick ?? member.user.username)")
                                            .foregroundColor(Color.accentColor)
                                            .underline()
                                        +
                                        Text(" ")
                                    ))
                                } else { throw "no member" }
                            } catch {
                                try? wss.getMembers(ids: [id], guild: channelInfo.guild)
                            }
                        }
                    }
                }

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
                Task.detached {
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

            if #available(macOS 12.0, *), highlight {
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
    public class func markLine(_ line: String, _ members: [String: String] = [:], font: Bool, highlight: Bool, allowLinkShortening: Bool, channelInfo: (guild: String, channel: String)) -> TextArrayPublisher {
        var line = line
        if !allowLinkShortening {
            line = line.replacingOccurrences(of: "](", with: "]\(blankCharacter)(") // disable link shortening forcefully
        }
                
        let words = line.matchRange(precomputed: RegexExpressions.line).map { line[$0].trimmingCharacters(in: .whitespaces) }
        
        var overrideFont: Font? = nil
        if let firstWord = words.first, line.hasPrefix("# ") || line.hasPrefix("## ") || line.hasPrefix("### ") {
            overrideFont = .system(size: CGFloat(16 + 24 / firstWord.count), weight: .bold)
        }
        
        let pubs: [AnyPublisher<Text, Error>] = words.map {
            markWord($0, members, font: font, highlight: highlight, quote: line.first == $0.first, channelInfo: channelInfo)
        }
        return Publishers.MergeMany(pubs)
            .collect()
            .map {
                if let overrideFont { return $0.map { $0.font(overrideFont) } }
                return $0
            }
            .eraseToAnyPublisher()
    }

    /**
     markAll: Simple Publisher that combines an array of word and line publishers for a text section
     - Parameter text: The text being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    @_optimize(speed)
    public class func markAll(text: String, _ members: [String: String] = [:], font: Bool = false, allowLinkShortening: Bool = false, channelInfo: (guild: String, channel: String)) -> TextPublisher {
        let newlines = text.split(whereSeparator: \.isNewline)

        let codeBlockMarkerRawOffsets = newlines
            .enumerated()
            .compactMap { (offset, element) -> Int? in
                guard element.prefix(3) == "```" || element.suffix(3) == "```" else { return nil }
                return offset
            }

        let indexes = codeBlockMarkerRawOffsets
            .indices
            .compactMap { number -> (Int, Int)? in
                guard number % 2 == 0 else { return nil }
                if !codeBlockMarkerRawOffsets.indices.contains(number + 1) { return nil }
                return (codeBlockMarkerRawOffsets[number], codeBlockMarkerRawOffsets[number + 1])
            }

        let pubs = newlines.map { markLine(String($0), members, font: font, highlight: (text.count > 100) && highlighting, allowLinkShortening: allowLinkShortening, channelInfo: channelInfo) }
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

        static var italic: FastRegex? = {
            try? NSRegularExpression(pattern: #"(\*|_)(.*?)\1"#)
        }()
        static var bold: FastRegex? = {
            try? NSRegularExpression(pattern: #"(\*\*|__)(.*?)\1"#)
        }()
        static var strikeThrough: FastRegex? = {
            try? NSRegularExpression(pattern: #"(\*\*|__)(.*?)\1"#)
        }()
        static var mono: FastRegex? = {
            try? NSRegularExpression(pattern: #"(`(\w+(\s\w+)*)`)"#)
        }()
    }
}

extension Array where Element == String {
    func replaceAllOccurences(of original: String, with string: String) -> [String] {
        map { $0.replacingOccurrences(of: original, with: string) }
    }
}

//
//  Markdown.swift
//  Accord
//
//  Created by evelyn on 2021-11-18.
//

import Foundation
import AppKit
import SwiftUI
import Combine

extension String {
    func matches(for regex: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: regex)
        let results = regex?.matches(in: self, range: NSRange(self.startIndex..., in: self))
        guard let mapped = results?.compactMap({ (result) -> String? in
            if let range = Range(result.range, in: self) {
                return String(self[range])
            } else {
                return nil
            }
        }) else {
            return []
        }
        return mapped
    }
    func matchRange(for regex: String) -> [Range<String.Index>] {
        let regex = try? NSRegularExpression(pattern: regex)
        let results = regex?.matches(in: self, range: NSRange(self.startIndex..., in: self))
        guard let mapped = results?.compactMap({ Range($0.range, in: self) }) else {
            return []
        }
        return mapped
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...].range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

extension Array where Element == String {
    @inlinable func replaceAllOccurences(of original: String, with string: String) -> [String] {
        self.map { $0.replacingOccurrences(of: original, with: string) }
    }
}

final public class Markdown {

    enum MarkdownErrors: Error {
        case unsupported // For the new Markdown Parser, which is unavailable on Big Sur
    }

    public typealias TextPublisher = AnyPublisher<Text, Error>
    public typealias TextArrayPublisher = AnyPublisher<[Text], Error>

    /// Publisher that sends a SwiftUI Text view with a newline
    static public var newLinePublisher: TextArrayPublisher = Just<[Text]>.init([Text("\n")]).setFailureType(to: Error.self).eraseToAnyPublisher()
    static fileprivate let blankCharacter = "‎" // Not an empty string

    /**
     markWord: Simple Publisher that sends a text view with the processed word
     - Parameter word: The String being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    public class func markWord(_ word: String, _ members: [String: String] = [:]) -> TextPublisher {
        let emoteIDs = word.matches(for: #"(?<=\:)(\d+)(.*?)(?=\>)"#)
        if let id = emoteIDs.first, let emoteURL = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?size=16") {
            return RequestPublisher.image(url: emoteURL)
                .replaceNil(with: NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "No connection") ?? NSImage())
                .map { Text("\(Image(nsImage: $0))") + Text(" ") }
                .eraseToAnyPublisher()
        }
        let inlineImages = word.matches(for: #"(?:([^:\/?#]+):)?(?:\/\/([^\/?#]*))?([^?#]*\.(?:jpg|gif|png))(?:\?([^#]*))?(?:#(.*))?"#).filter { $0.contains("nitroless") || $0.contains("emote") || $0.contains("emoji") } // nitroless emoji
        if let url = inlineImages.first, let emoteURL = URL(string: url) {
            return RequestPublisher.image(url: emoteURL)
                .replaceNil(with: NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "No connection") ?? NSImage())
                .map { Text("\(Image(nsImage: $0))") + Text(" ") }
                .eraseToAnyPublisher()
        }
        return Deferred { Future { promise in
            let mentions = word.matches(for: #"(?<=\@|@!)(\d+)(.*?)(?=\>)"#)
            let songIDs = word.matches(for: #"(?<=https:\/\/open\.spotify\.com\/track\/|https:\/\/music\.apple\.com\/[a-z][a-z]\/album\/[a-zA-Z\d%\(\)-]{1,100}\/|https://tidal\.com/browse/track/)(?:(?!\?).)*"#)
            let platforms = word.matches(for: #"(spotify|music\.apple|tidal)"#)
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
                return promise(.success(Text("@\(members[id] ?? "Unknown user") ").foregroundColor(Color(NSColor.controlAccentColor)).underline() + Text(" ")))
            }
            do {
                if #available(macOS 12, *) {
                    let markdown = try AttributedString(markdown: word)
                    return promise(.success(Text(markdown) + Text(" ")))
                } else { throw MarkdownErrors.unsupported }
            } catch {
                return promise(.success(Text(word) + Text(" ")))
            }
        } }.eraseToAnyPublisher()
    }

    /**
     markLine: Simple Publisher that combines an array of word publishers for a split line
     - Parameter line: The line being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with array of SwiftUI Text views
     **/
    public class func markLine(_ line: String, _ members: [String: String] = [:]) -> TextArrayPublisher {
        let line = line.replacingOccurrences(of: "](", with: "]\(blankCharacter)(") // disable link shortening forcefully
        let regex = #"\*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+"#
        let words = line.ranges(of: regex, options: .regularExpression).map { line[$0].trimmingCharacters(in: .whitespaces) }
        let pubs: [AnyPublisher<Text, Error>] = words.map { markWord($0, members) }
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
    public class func markAll(text: String, _ members: [String: String] = [:]) -> TextPublisher {
        let newlines = text.split(whereSeparator: \.isNewline)
        let pubs = newlines.map { markLine(String($0), members) }
        let withNewlines: [TextArrayPublisher] = Array(pubs.map { [$0] }.joined(separator: [newLinePublisher]))
        return Publishers.MergeMany(withNewlines)
            .map { $0.reduce(Text(""), +) }
            .mapError { $0 as Error }
            .collect()
            .map { $0.reduce(Text(""), +) }
            .eraseToAnyPublisher()
            .debugAssertNoMainThread()
    }

}

final class NSAttributedMarkdown {
    public class func markdown(_ text: String, font: NSFont?) -> NSMutableAttributedString {
        let mut = NSMutableAttributedString(string: text)
        let italic = text.matchRange(for: #"(\*|_)(.*?)\1"#)
        let bold = text.matchRange(for: #"(\*\*|__)(.*?)\1"#)
        let strikeThrough = text.matchRange(for: #"(~~(\w+(\s\w+)*)~~)"#)
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
        let font = NSFont.boldSystemFont(ofSize: 13)
        return font
    }
}

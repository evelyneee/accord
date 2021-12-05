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
        guard let mapped = results?.compactMap( { Range($0.range, in: self) } ) else {
            return []
        }
        return mapped
    }
}

extension Array where Element == String {
    @inlinable func replaceAllOccurences(of original: String, with string: String) -> [String] {
        var ret = [String]()
        for i in self {
            ret.append(i.replacingOccurrences(of: original, with: string))
        }
        return ret
    }
}

final public class Markdown {
    
    enum MarkdownErrors: Error {
        case unsupported // For the new Markdown Parser, which is unavailable on Big Sur
    }
    
    /// Publisher that sends a SwiftUI Text view with a newline
    static public var newLinePublisher: AnyPublisher<[Text], Error> = Just<[Text]>.init([Text("\n")]).setFailureType(to: Error.self).eraseToAnyPublisher()
    
    /**
     # markWord: Simple Publisher that sends a text view with the processed word
     - Parameter word: The String being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    public class func markWord(_ word: String, _ members: [String:String] = [:]) -> AnyPublisher<Text, Error> {
        return Deferred {
            Future { promise in
                let emoteIDs = word.matches(for: #"(?<=\:)(\d+)(.*?)(?=\>)"#)
                let mentions = word.matches(for: #"(?<=\@|@!)(\d+)(.*?)(?=\>)"#)
                let songIDs = word.matches(for: #"(?<=https:\/\/open\.spotify\.com\/track\/|https:\/\/music\.apple\.com\/[a-z][a-z]\/album\/[a-zA-Z\d%\(\)-]{1,100}\/|https://tidal\.com/browse/track/)(?:(?!\?).)*"#)
                let platforms = word.matches(for: #"(spotify|music\.apple|tidal)"#)
                    .replaceAllOccurences(of: "music.apple", with: "applemusic")
                let dict = Array(arrayLiteral: zip(songIDs, platforms))
                    .reduce([], +)
                for (id, platform) in dict {
                    SongLink.shared.getSong(song: "\(platform):track:\(id)") { song in
                        guard let song = song else { return }
                        switch musicPlatform {
                        case .appleMusic:
                            promise(.success(Text(song.linksByPlatform.appleMusic.url).foregroundColor(Color.blue).underline() + Text(" ")))
                            return
                        case .spotify:
                            promise(.success(Text(song.linksByPlatform.spotify?.url ?? word).foregroundColor(Color.blue).underline() + Text(" ")))
                            return
                        case .none:
                            promise(.success(Text(word) + Text(" ")))
                            return
                        default: break
                        }
                    }
                }
                for id in emoteIDs {
                    if let emoteURL = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?size=40") {
                        Request.image(url: emoteURL, to: CGSize(width: 40, height: 40)) { image in
                            guard let image = image else {
                                promise(.success(Text(word) + Text(" ")))
                                return
                            }
                            promise(.success(Text("\(Image(nsImage: image))") + Text(" ")))
                            return
                        }
                    }
                }
                for id in mentions {
                    promise(.success(Text("@\(members[id] ?? "Unknown user") ").foregroundColor(Color(NSColor.controlAccentColor)).underline() + Text(" ")))
                    return
                }
                do {
                    if #available(macOS 12, *) {
                        let markdown = try AttributedString(markdown: word)
                        promise(.success(Text(markdown) + Text(" ")))
                        return
                    } else { throw MarkdownErrors.unsupported }
                } catch {
                    promise(.success(Text(word) + Text(" ")))
                    return
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /**
     # markLine: Simple Publisher that combines an array of word publishers for a split line
     - Parameter line: The line being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with array of SwiftUI Text views
     **/
    public class func markLine(_ line: String, _ members: [String:String] = [:]) -> AnyPublisher<[Text], Error> {
        let words: [String] = line.split(separator: " ").compactMap { $0.str() }
        let pubs: [AnyPublisher<Text, Error>] = words.map { markWord($0, members) }
        return Publishers.MergeMany(pubs)
            .collect()
            .eraseToAnyPublisher()
    }
    
    /**
     # markLine: Simple Publisher that combines an array of word and line publishers for a text section
     - Parameter text: The text being processed
     - Parameter members: Dictionary of channel members from which we get the mentions
     - Returns AnyPublisher with SwiftUI Text view
     **/
    public class func markAll(text: String, _ members: [String:String] = [:]) -> AnyPublisher<Text, Error> {
        let newlines = text.split(whereSeparator: \.isNewline)
        let pubs = newlines.map { markLine(String($0), members) }
        let withNewlines: [AnyPublisher<[Text], Error>] = Array(pubs.map { [$0] }.joined(separator: [newLinePublisher]))
        return Publishers.MergeMany(withNewlines)
            .map { $0.reduce(Text(""), +) }
            .mapError { $0 as Error }
            .collect()
            .map { $0.reduce(Text(""), +) }
            .eraseToAnyPublisher()
    }
    
}

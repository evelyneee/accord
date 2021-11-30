//
//  Markdown.swift
//  Accord
//
//  Created by evelyn on 2021-11-18.
//

import Foundation
import AppKit
import SwiftUI

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

final class Markdown {
    typealias completionBlock = ((_ value: Optional<NSAttributedString>) -> Void)

    enum MarkdownErrors: Error {
        case unsupported
    }
    
    final public class func marked(for orig: String, members: [String:String] = [:], completion: @escaping completionBlock) {
        var text = orig
        let codeblocks = text.matchRange(for: #"(?<=```.{0,10}\n)(.|\n)*(?=\n```)"#)
        for codeblock in codeblocks {
            text.removeSubrange(codeblock)
        }
        let newlines = text.split(whereSeparator: \.isNewline)
        let attributed: NSMutableAttributedString = NSMutableAttributedString.init(string: "")
        let attribute: [NSAttributedString.Key: Any] = [.font:NSFont.systemFont(ofSize: 13)]
        for (index, line) in newlines.enumerated() {
            let words: [String] = line.split(separator: " ").compactMap { $0.str() }
            for word in words {
                
                let emoteIDs = word.matches(for: #"(?<=\:)(\d+)(.*?)(?=\>)"#)
                let mentions = word.matches(for: #"(?<=\@|@!)(\d+)(.*?)(?=\>)"#)
                let songIDs = word.matches(for: #"(?<=https:\/\/open\.spotify\.com\/track\/|https:\/\/music\.apple\.com\/[a-z][a-z]\/album\/[a-zA-Z\d%\(\)-]{1,100}\/|https://tidal\.com/browse/track/)(?:(?!\?).)*"#)
                let platforms = word.matches(for: #"(spotify|music\.apple|tidal)"#)
                    .replaceAllOccurences(of: "music.apple", with: "applemusic")
                let dict = Array(arrayLiteral: zip(songIDs, platforms))
                    .reduce([], +)
                /*
                // Syntax highlighting
                let languageKeywords = word.matches(for: #"(func|guard|let|var|return|for|self|try)"#)
                let miscKeywords = word.matches(for: #"(function|fetch|const)"#)
                let typeKeywords = word.matches(for: #"(String|str|Any|Int|Int64|Int32)"#)
                let function = word.matches(for: #".*\(\)$"#)


                let whitemonospace: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)]

                for item in languageKeywords {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                                         .foregroundColor: NSColor.purple]
                    attributed.append(NSAttributedString.init(string: item, attributes: fontAttributes))
                    continue
                }
                for item in typeKeywords {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                                         .foregroundColor: NSColor.green]
                    attributed.append(NSAttributedString.init(string: item, attributes: fontAttributes))
                    continue
                }
                for item in miscKeywords {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                                         .foregroundColor: NSColor.orange]
                    attributed.append(NSAttributedString.init(string: item, attributes: fontAttributes))
                    continue
                }
                for item in function {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                                         .foregroundColor: NSColor.red]
                    attributed.append(NSAttributedString.init(string: item.dropLast(2).str(), attributes: fontAttributes))
                    attributed.append(NSAttributedString.init(string: "()", attributes: whitemonospace))
                    continue
                }
                if (!(languageKeywords.isEmpty) || !(miscKeywords.isEmpty) || !(typeKeywords.isEmpty) || !(function.isEmpty)) {
                    attributed.append(" ".attributed)
                    continue
                }
                */
                for (id, platform) in dict {
                    SongLink.shared.getSong(song: "\(platform):track:\(id)") { song in
                        guard let song = song else { return }
                        let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.systemFont(ofSize: 13),
                                                                             .foregroundColor: NSColor.blue,
                                                                             .underlineStyle: NSUnderlineStyle.single]
                        switch musicPlatform {
                        case .appleMusic:
                            attributed.append(NSAttributedString(string: song.linksByPlatform.appleMusic.url, attributes: fontAttributes))
                        case .spotify:
                            attributed.append(NSAttributedString(string: song.linksByPlatform.spotify?.url ?? word, attributes: fontAttributes))
                        case .none:
                            break
                        default: break
                        }
                    }
                }
                if dict.isEmpty == false {
                    attributed.append(NSAttributedString(string: " ", attributes: attribute))
                    continue
                }
                for id in emoteIDs {
                    if let emoteURL = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?size=40") {
                        Request.image(url: emoteURL, to: CGSize(width: 40, height: 40)) { image in
                            let attachment = NSTextAttachment()
                            attachment.image = image
                            attributed.append(NSAttributedString(attachment: attachment))
                        }
                    }
                }
                if emoteIDs != [] {
                    attributed.append(NSAttributedString(string: " ", attributes: attribute))
                    continue
                }
                for id in mentions {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.systemFont(ofSize: 13),
                                                                         .foregroundColor: NSColor.controlAccentColor,
                                                                         .underlineStyle: NSUnderlineStyle.single]
                    attributed.append(NSAttributedString(string: "@\(members[id] ?? "Unknown user") ", attributes: fontAttributes))
                }
                if mentions != [] {
                    attributed.append(NSAttributedString(string: " ", attributes: attribute))
                    continue
                }
                do {
                    if #available(macOS 12, *) {
                        let attribute: [NSAttributedString.Key: Any] = [.font:NSFont.systemFont(ofSize: 13)]
                        let markdown = try NSMutableAttributedString.init(markdown: word)
                        markdown.addAttributes(attribute, range: NSMakeRange(0, markdown.length))
                        attributed.append(NSAttributedString.init(attributedString: markdown))
                    } else { throw MarkdownErrors.unsupported }
                } catch {
                    attributed.append(NSAttributedString(string: word, attributes: attribute))
                }
                attributed.append(NSAttributedString(string: " ", attributes: attribute))
            }
            if index != newlines.count - 1 {
                attributed.append(NSAttributedString(string: "\n", attributes: attribute))
            }
        }
        for codeblock in codeblocks {
            attributed.append(NSAttributedString(string: "\n", attributes: attribute))
            let attribute: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                            .backgroundColor:NSColor.darkGray,
                                                            .foregroundColor:NSColor.white]
            attributed.append(NSAttributedString(string: String(orig[codeblock]), attributes: attribute))
        }
        return completion(attributed)
    }
}

public extension String {
    typealias swiftUIBlock = ((_ value: Optional<Text>) -> Void)
    func markdown(members: [String:String] = [:], _ completion: @escaping swiftUIBlock) {
        enum MarkdownErrors: Error {
            case unsupported
        }
        let text = self
        let newlines = text.split(whereSeparator: \.isNewline)
        var attributed = [Text]() {
            didSet {
                if attributed.count >= text.components(separatedBy: " ").count {
                    return completion(attributed.reduce(Text(""), +))
                }
            }
        }
        for (index, line) in newlines.enumerated() {
            let words: [String] = line.split(separator: " ").compactMap { $0.str() }
            for word in words {
                
                let emoteIDs = word.matches(for: #"(?<=\:)(\d+)(.*?)(?=\>)"#)
                let mentions = word.matches(for: #"(?<=\@|@!)(\d+)(.*?)(?=\>)"#)
                let songIDs = word.matches(for: #"(?<=https:\/\/open\.spotify\.com\/track\/|https:\/\/music\.apple\.com\/[a-z][a-z]\/album\/[a-zA-Z\d%\(\)-]{1,100}\/|https://tidal\.com/browse/track/)(?:(?!\?).)*"#)
                let platforms = word.matches(for: #"(spotify|music\.apple|tidal)"#)
                    .replaceAllOccurences(of: "music.apple", with: "applemusic")
                let dict = Array(arrayLiteral: zip(songIDs, platforms))
                    .reduce([], +)
                /*
                // Syntax highlighting
                let languageKeywords = word.matches(for: #"(func|guard|let|var|return|for|self|try)"#)
                let miscKeywords = word.matches(for: #"(function|fetch|const)"#)
                let typeKeywords = word.matches(for: #"(String|str|Any|Int|Int64|Int32)"#)
                let function = word.matches(for: #".*\(\)$"#)


                let whitemonospace: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)]

                for item in languageKeywords {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                                         .foregroundColor: NSColor.purple]
                    attributed.append(NSAttributedString.init(string: item, attributes: fontAttributes))
                    continue
                }
                for item in typeKeywords {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                                         .foregroundColor: NSColor.green]
                    attributed.append(NSAttributedString.init(string: item, attributes: fontAttributes))
                    continue
                }
                for item in miscKeywords {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                                         .foregroundColor: NSColor.orange]
                    attributed.append(NSAttributedString.init(string: item, attributes: fontAttributes))
                    continue
                }
                for item in function {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                                                                         .foregroundColor: NSColor.red]
                    attributed.append(NSAttributedString.init(string: item.dropLast(2).str(), attributes: fontAttributes))
                    attributed.append(NSAttributedString.init(string: "()", attributes: whitemonospace))
                    continue
                }
                if (!(languageKeywords.isEmpty) || !(miscKeywords.isEmpty) || !(typeKeywords.isEmpty) || !(function.isEmpty)) {
                    attributed.append(" ".attributed)
                    continue
                }
                */
                for (id, platform) in dict {
                    SongLink.shared.getSong(song: "\(platform):track:\(id)") { song in
                        guard let song = song else { return }
                        switch musicPlatform {
                        case .appleMusic:
                            attributed.append(Text(song.linksByPlatform.appleMusic.url).foregroundColor(Color.blue).underline())
                        case .spotify:
                            attributed.append(Text(song.linksByPlatform.spotify?.url ?? word).foregroundColor(Color.blue).underline())
                        case .none:
                            attributed.append(Text(text))
                        default: break
                        }
                    }
                }
                if dict.isEmpty == false {
                    attributed.append(Text(" "))
                    continue
                }
                for id in emoteIDs {
                    if let emoteURL = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?size=40") {
                        Request.image(url: emoteURL, to: CGSize(width: 40, height: 40)) { image in
                            guard let image = image else {
                                attributed.append(Text(text))
                                return
                            }
                            attributed.append(Text("\(Image(nsImage: image))"))
                        }
                    }
                }
                if emoteIDs != [] {
                    attributed.append(Text(" "))
                    continue
                }
                for id in mentions {
                    attributed.append(Text("@\(members[id] ?? "Unknown user") ").foregroundColor(Color(NSColor.controlAccentColor)).underline())
                }
                if mentions != [] {
                    attributed.append(Text(" "))
                    continue
                }
                do {
                    if #available(macOS 12, *) {
                        let markdown = try AttributedString(markdown: word)
                        attributed.append(Text(markdown))
                    } else { throw MarkdownErrors.unsupported }
                } catch {
                    attributed.append(Text(word))
                }
                attributed.append(Text(" "))
            }
            if index != newlines.count - 1 {
                attributed.append(Text("\n"))
            }
        }
    }
}

struct AttributedTextRepresentable: NSViewRepresentable, Equatable {

    typealias NSViewType = NSTextField
    let attributed: NSAttributedString
    var limit: Int?
    
    func makeNSView(context: Context) -> NSViewType {
        let textView = NSTextField(labelWithAttributedString: attributed)
        if let limit = limit {
            textView.maximumNumberOfLines = limit + 1
        }
        return textView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
    }
    
    @inlinable func lineLimit(_ limit: Int) -> AttributedTextRepresentable {
        var view = self
        view.limit = limit
        return view
    }
}

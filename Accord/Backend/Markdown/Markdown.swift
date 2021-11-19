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
    var attributed: NSAttributedString {
        let attribute: [NSAttributedString.Key: Any] = [.font:NSFont.systemFont(ofSize: 13)]
        return NSAttributedString(string: self, attributes: attribute)
    }
    func matches(for regex: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            let mapped = results.map {
                String(self[Range($0.range, in: self)!])
            }
            return mapped
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
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
    typealias completionBlock = ((_ value: NSAttributedString) -> Void)
    static let testStrings = """
    This is a *text* 1
    This is a newline 2 <:nwholesome:896129474800779304>
    """
    
    enum MarkdownErrors: Error {
        case unsupported
    }
    
    final public class func marked(for text: String, members: [String:String] = [:], completion: @escaping completionBlock) {
        let newlines = text.split(whereSeparator: \.isNewline)
        let attributed: NSMutableAttributedString = NSMutableAttributedString.init(string: "")
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
                for (id, platform) in dict {
                    SongLink.shared.getSong(song: "\(platform):track:\(id)") { song in
                        guard let song = song else {
                            return
                        }
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
                    continue
                }
                for id in emoteIDs {
                    if let emoteURL = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?size=40") {
                        Request.image(url: emoteURL, to: CGSize(width: 40, height: 40)) { image in
                            if let image = image {
                                print("Based \(image.size)")
                                let attachment = NSTextAttachment()
                                attachment.image = image
                                let str = NSAttributedString(attachment: attachment)
                                attributed.append(str)
                            }
                        }
                    }
                }
                if emoteIDs != [] {
                    continue
                }
                for id in mentions {
                    let fontAttributes: [NSAttributedString.Key: Any] = [.font:NSFont.systemFont(ofSize: 13),
                                                                         .foregroundColor: NSColor.blue,
                                                                         .underlineStyle: NSUnderlineStyle.single]
                    attributed.append(NSAttributedString(string: "@\(members[id] ?? "Unknown user") ", attributes: fontAttributes))
                }
                if mentions != [] {
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
                    attributed.append(word.attributed)
                }
                attributed.append(" ".attributed)
            }
            if index != newlines.count - 1 {
                attributed.append("\n".attributed)
            }
        }
        return completion(attributed)
    }
}

struct AttributedTextRepresentable: NSViewRepresentable {

    typealias NSViewType = NSTextField
    let attributed: NSAttributedString

    func makeNSView(context: Context) -> NSViewType {
        let textView = NSTextField(labelWithAttributedString: attributed)
        return textView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.attributedStringValue = attributed
    }
}

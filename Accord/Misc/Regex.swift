//
//  RegexExpressions.swift
//  Accord
//
//  Created by evelyn on 2022-03-07.
//

import Foundation

enum RegexExpressions {
    static func precompute() {
        _ = (
            fullEmoji,
            emojiID,
            songIDs,
            mentions,
            platforms,
            channels,
            line,
            chatTextMentions,
            chatTextChannels,
            chatTextSlashCommand,
            chatTextEmoji,
            completedEmote
        )
    }
    
    static var enableNativeRegex: Bool = true
    
    static var fullEmoji: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /<:\w+:[0-9]+>/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.fullEmoji.rawValue)
        }
    }()
    
    static var emojiID: FastRegex = {
        try! NSRegularExpression(pattern: RegexLiterals.emojiID.rawValue)
    }()
    
    static var songIDs: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return #/(https:\/\/open\.spotify\.com\/track\/|https:\/\/music\.apple\.com\/[a-z][a-z]\/album\/[a-zA-Z\d%\(\)-]{1,100}\/|https:\/\/tidal\.com\/browse\/track\/)(?:(?!\?).)*/#
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.songIDs.rawValue)
        }
    }()
    
    static var mentions: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(?:\@|@!)(\d+)(.*?)(?=\>)/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.mentions.rawValue)
        }
    }()
    
    static var roleMentions: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(?:\@&)(\d+)(.*?)(?=\>)/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.roleMentions.rawValue)
        }
    }()

    static var platforms: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(spotify|music\.apple|tidal)/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.platforms.rawValue)
        }
    }()
    
    static var channels: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(?:\#)(\d+)(.+?)(?=\>)/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.channels.rawValue)
        }
    }()

    static var line: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /\*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.line.rawValue)
        }
    }()

    static var chatTextMentions: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(?:@)(?:(?!\s).)*/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.chatTextMentions.rawValue)
        }
    }()

    static var chatTextChannels: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(?:#)(?:(?!\s).)*/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.chatTextChannels.rawValue)
        }
    }()

    static var chatTextSlashCommand: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(?:\/)(?:(?!\s).)*/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.chatTextSlashCommand.rawValue)
        }
    }()

    static var chatTextEmoji: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(?::).*/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.chatTextEmoji.rawValue)
        }
    }()

    static var completedEmote: FastRegex = {
        if enableNativeRegex, #available(macOS 13.0, *) {
            return /(?:^|[^<]|[^<]a):.+:/
        } else {
            return try! NSRegularExpression(pattern: RegexLiterals.completedEmote.rawValue)
        }
    }()

}

protocol FastRegex {
    func matches(in str: String, options: NSRegularExpression.MatchingOptions, range: NSRange) -> [Range<String.Index>]
}

extension NSRegularExpression: FastRegex {
    func matches(in str: String, options: MatchingOptions, range: NSRange) -> [Range<String.Index>] {
        return self.matches(in: str, range: range).map { print(str, $0.range.lowerBound, $0.range.upperBound); return Range($0.range, in: str)! }
    }
    
}

class RegexReturnValue {
    var range: Range<String.Index>
    init(range: Range<String.Index>) {
        
        self.range = range
    }
}


@available(macOS 13.0, *)
extension Regex: FastRegex {
    func matches(in str: String, options: NSRegularExpression.MatchingOptions, range: NSRange) -> [Range<String.Index>] {
        return str.matches(of: self).map(\.range)
    }
}

enum RegexLiterals: String, RawRepresentable {
    case fullEmoji = #"<:\w+:[0-9]+>"#
    case emojiID = #"(?<=\:)(\d+)(.*?)(?=\>)"#
    case songIDs = #"(?<=https:\/\/open\.spotify\.com\/track\/|https:\/\/music\.apple\.com\/[a-z][a-z]\/album\/[a-zA-Z\d%\(\)-]{1,100}\/|https://tidal\.com/browse/track/)(?:(?!\?).)*"#
    case mentions = #"(?<=\@|@!)(\d+)(.*?)(?=\>)"#
    case roleMentions = #"(?<=\@&)(\d+)(.*?)(?=\>)"#
    case platforms = #"(spotify|music\.apple|tidal)"#
    case channels = ##"(?<=\#)(\d+)(.+?)(?=\>)"##
    case line = #"\*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+"#
    case chatTextMentions = #"(?<=@)(?:(?!\ ).)*"#
    case chatTextChannels = #"(?<=#)(?:(?!\ ).)*"#
    case chatTextSlashCommand = #"(?<=\/)(?:(?!\ ).)*"#
    case chatTextEmoji = #"(?<=:).*"#
    case completedEmote = "(?<!<|<a):.+:"
}

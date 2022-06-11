//
//  RegexExpressions.swift
//  Accord
//
//  Created by evelyn on 2022-03-07.
//

import Foundation
import RegexBuilder

enum RegexExpressions {
    static func precompute() {
        _ = (
            fullEmojiRegex,
            emojiIDRegex,
            songIDsRegex,
            mentionsRegex,
            platformsRegex,
            channelsRegex,
            lineRegex,
            chatTextMentionsRegex,
            chatTextChannelsRegex,
            chatTextSlashCommandRegex,
            chatTextEmojiRegex,
            completedEmoteRegex
        )
    }

    static var fullEmojiRegex = try? NSRegularExpression(pattern: RegexLiterals.fullEmojiRegex.rawValue)
    static var emojiIDRegex = try? NSRegularExpression(pattern: RegexLiterals.emojiIDRegex.rawValue)
    static var songIDsRegex = try? NSRegularExpression(pattern: RegexLiterals.songIDsRegex.rawValue)
    static var mentionsRegex = try? NSRegularExpression(pattern: RegexLiterals.mentionsRegex.rawValue)
    static var platformsRegex = try? NSRegularExpression(pattern: RegexLiterals.platformsRegex.rawValue)
    static var channelsRegex = try? NSRegularExpression(pattern: RegexLiterals.channelsRegex.rawValue)
    static var lineRegex = try? NSRegularExpression(pattern: RegexLiterals.lineRegex.rawValue)
    static var chatTextMentionsRegex = try? NSRegularExpression(pattern: RegexLiterals.chatTextMentionsRegex.rawValue)
    static var chatTextChannelsRegex = try? NSRegularExpression(pattern: RegexLiterals.chatTextChannelsRegex.rawValue)
    static var chatTextSlashCommandRegex = try? NSRegularExpression(pattern: RegexLiterals.chatTextSlashCommandRegex.rawValue)
    static var chatTextEmojiRegex = try? NSRegularExpression(pattern: RegexLiterals.chatTextEmojiRegex.rawValue)
    static var completedEmoteRegex = try? NSRegularExpression(pattern: RegexLiterals.completedEmoteRegex.rawValue)
}

enum RegexLiterals: String, RawRepresentable {
    case fullEmojiRegex = #"<:\w+:[0-9]+>"#
    case emojiIDRegex = #"(?<=\:)(\d+)(.*?)(?=\>)"#
    case songIDsRegex = #"(?<=https:\/\/open\.spotify\.com\/track\/|https:\/\/music\.apple\.com\/[a-z][a-z]\/album\/[a-zA-Z\d%\(\)-]{1,100}\/|https://tidal\.com/browse/track/)(?:(?!\?).)*"#
    case mentionsRegex = #"(?<=\@|@!)(\d+)(.*?)(?=\>)"#
    case platformsRegex = #"(spotify|music\.apple|tidal)"#
    case channelsRegex = ##"(?<=\#)(\d+)(.+?)(?=\>)"##
    case lineRegex = #"\*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+"#
    case chatTextMentionsRegex = #"(?<=@)(?:(?!\ ).)*"#
    case chatTextChannelsRegex = #"(?<=#)(?:(?!\ ).)*"#
    case chatTextSlashCommandRegex = #"(?<=\/)(?:(?!\ ).)*"#
    case chatTextEmojiRegex = #"(?<=:).*"#
    case completedEmoteRegex = "(?<!<|<a):.+:"
}

/*
 @available(macOS 13.0, *)
 enum RegexRawLiterals {

     static func compute() {
         _ = (
             fullEmojiRegex,
             emojiIDRegex,
             songIDsRegex,
             mentionsRegex,
             platformsRegex,
             channelsRegex,
             lineRegex,
             chatTextMentionsRegex,
             chatTextChannelsRegex,
             chatTextSlashCommandRegex,
             chatTextEmojiRegex,
             completedEmoteRegex
         )
     }

     static var fullEmojiRegex = /<:\w+:[0-9]+>/
     static var emojiIDRegex = Regex {
         ":"
         Capture {
             OneOrMore(.digit)
         }
         Capture {
             ZeroOrMore(.any, .reluctant)
         }
         ">"
     }
     static var songIDsRegex = Regex {
         ChoiceOf {
             "https://open.spotify.com/track/"
             "https://music.apple.com/"
             ("a"..."z")
             ("a"..."z")
             "/album/"
             Repeat(1...100) {
                 CharacterClass(
                     .anyOf("%()-"),
                     ("a"..."z"),
                     ("A"..."Z"),
                     .digit
                 )
             }
             "/"
             "https://tidal.com/browse/track/"
         }
         ZeroOrMore {
             "?"
             One(.any)
         }
     }
     static var mentionsRegex = Regex {
         ChoiceOf {
             "@"
             "@!"
         }
         Capture {
             OneOrMore(.digit)
         }
         ">"
     }
     static var platformsRegex = /(spotify|music\.apple|tidal)/
     static var channelsRegex = Regex {
         "#"
         Capture {
             OneOrMore(.digit)
         }
         Capture {
             OneOrMore(.any, .reluctant)
         }
         ">"
     }
     static var lineRegex = Regex {
         OneOrMore {
             ChoiceOf {
                 Capture {
                     OneOrMore {
                         CharacterClass(
                             .anyOf("*~"),
                             .whitespace
                         )
                     }
                 }
                 Capture {
                     "*"
                     OneOrMore(.any)
                     "*"
                 }
                 Capture {
                     "~~"
                     OneOrMore(.any)
                     "~~"
                 }
                 Capture {
                     Repeat(1...3) {
                         "`"
                     }
                     OneOrMore(.any)
                     Repeat(1...3) {
                         "`"
                     }
                 }
             }
         }
     } // /\*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+/
     static var chatTextMentionsRegex = Regex {
         "@"
         ZeroOrMore {
             " "
             One(.any)
         }
     }
     static var chatTextChannelsRegex = Regex {
         "#"
         ZeroOrMore {
             " "
             One(.any)
         }
     }
     static var chatTextSlashCommandRegex = Regex {
         "/"
         ZeroOrMore {
             " "
             One(.any)
         }
     }
     static var chatTextEmojiRegex = Regex {
         ":"
         ZeroOrMore(.any)
     }
     static var completedEmoteRegex = Regex {
         ChoiceOf {
             "<"
             "<a"
         }
         ":"
         OneOrMore(.any)
         ":"
     }
 }

 final class RegexEngine {
     private init() {}

     @available(macOS, obsoleted: 13)
     class func matchRanges<S: StringProtocol>(for string: S, with regex: NSRegularExpression?) throws -> [Range<String.Index>] {
         let string = String(string)
         return string.matchRange(precomputed: regex)
     }

     @available(macOS, obsoleted: 13)
     class func matches<S: StringProtocol>(for string: S, with regex: NSRegularExpression?) throws -> [String] {
         try self.matchRanges(for: string, with: regex).map { String(string[$0]) }
     }

     @available(macOS 13.0, *)
     class func matchRanges<S: StringProtocol>(for string: S, with regex: any RegexComponent) throws -> [Range<String.Index>] {
         let string = String(string)
         return string.ranges(of: regex)
     }

     @available(macOS 13.0, *)
     class func matches<S: StringProtocol, R: RegexComponent>(for string: S, with regex: R) -> [String] where R.RegexOutput == (Substring, Substring, Substring) {
         let string = String(string)
         return string
             .matches(of: regex)
             .map(\.output)
             .map(\.0.stringLiteral)
     }

     @available(macOS 13.0, *)
     class func matches<S: StringProtocol, R: RegexComponent>(for string: S, with regex: R) -> [String] where R.RegexOutput == (Substring, Substring) {
         let string = String(string)
         print(string)
         return string
             .matches(of: regex)
             .map(\.output)
             .map(\.0.stringLiteral)
     }

     @available(macOS 13.0, *)
     class func matches<S: StringProtocol, R: RegexComponent>(for string: S, with regex: R) -> [String] where R.RegexOutput == Substring {
         let string = String(string)
         return string
             .matches(of: regex)
             .map(\.output)
             .map(\.stringLiteral)
     }

     @available(macOS 13.0, *)
     class func matches<S: StringProtocol, R: RegexComponent>(for string: S, with regex: R) -> [String] where R.RegexOutput == (Substring, Substring?) {
         let string = String(string)
         return string
             .matches(of: regex)
             .map(\.output)
             .map(\.0.stringLiteral)
     }
 }
 */

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

    static var fullEmoji = try? NSRegularExpression(pattern: RegexLiterals.fullEmoji.rawValue)
    static var emojiID = try? NSRegularExpression(pattern: RegexLiterals.emojiID.rawValue)
    static var songIDs = try? NSRegularExpression(pattern: RegexLiterals.songIDs.rawValue)
    static var mentions = try? NSRegularExpression(pattern: RegexLiterals.mentions.rawValue)
    static var roleMentions = try? NSRegularExpression(pattern: RegexLiterals.roleMentions.rawValue)
    static var platforms = try? NSRegularExpression(pattern: RegexLiterals.platforms.rawValue)
    static var channels = try? NSRegularExpression(pattern: RegexLiterals.channels.rawValue)
    static var line = try? NSRegularExpression(pattern: RegexLiterals.line.rawValue)
    static var chatTextMentions = try? NSRegularExpression(pattern: RegexLiterals.chatTextMentions.rawValue)
    static var chatTextChannels = try? NSRegularExpression(pattern: RegexLiterals.chatTextChannels.rawValue)
    static var chatTextSlashCommand = try? NSRegularExpression(pattern: RegexLiterals.chatTextSlashCommand.rawValue)
    static var chatTextEmoji = try? NSRegularExpression(pattern: RegexLiterals.chatTextEmoji.rawValue)
    static var completedEmote = try? NSRegularExpression(pattern: RegexLiterals.completedEmote.rawValue)
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

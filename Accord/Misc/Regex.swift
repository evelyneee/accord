//
//  Regex.swift
//  Accord
//
//  Created by evelyn on 2022-03-07.
//

import Foundation

enum Regex {
    static func precompute() {
        _ = (
            fullEmojiRegex,
            lineSplitRegex,
            emojiIDRegex,
            songIDsRegex,
            mentionsRegex,
            inlineImageRegex,
            platformsRegex,
            channelsRegex,
            lineRegex,
            chatTextMentionsRegex,
            chatTextChannelsRegex,
            chatTextSlashCommandRegex,
            chatTextEmojiRegex
        )
    }

    static var fullEmojiRegex = try? NSRegularExpression(pattern: #"<:\w+:[0-9]+>"#)
    static var lineSplitRegex = try? NSRegularExpression(pattern: #"\*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+"#)
    static var emojiIDRegex = try? NSRegularExpression(pattern: #"(?<=\:)(\d+)(.*?)(?=\>)"#)
    static var songIDsRegex = try? NSRegularExpression(pattern: #"(?<=https:\/\/open\.spotify\.com\/track\/|https:\/\/music\.apple\.com\/[a-z][a-z]\/album\/[a-zA-Z\d%\(\)-]{1,100}\/|https://tidal\.com/browse/track/)(?:(?!\?).)*"#)
    static var mentionsRegex = try? NSRegularExpression(pattern: #"(?<=\@|@!)(\d+)(.*?)(?=\>)"#)
    static var inlineImageRegex = try? NSRegularExpression(pattern: #"(?:([^:\/?#]+):)?(?:\/\/([^\/?#]*))?([^?#]*\.(?:jpg|gif|png))(?:\?([^#]*))?(?:#(.*))?"#)
    static var platformsRegex = try? NSRegularExpression(pattern: #"(spotify|music\.apple|tidal)"#)
    static var channelsRegex = try? NSRegularExpression(pattern: ##"(?<=\#)(\d+)(.+?)(?=\>)"##)
    static var lineRegex = try? NSRegularExpression(pattern: #"\*.+\*|~~.+~~|`{1,3}.+`{1,3}|([^*~\s]+)+"#)
    static var chatTextMentionsRegex = try? NSRegularExpression(pattern: #"(?<=@)(?:(?!\ ).)*"#)
    static var chatTextChannelsRegex = try? NSRegularExpression(pattern: #"(?<=#)(?:(?!\ ).)*"#)
    static var chatTextSlashCommandRegex = try? NSRegularExpression(pattern: #"(?<=\/)(?:(?!\ ).)*"#)
    static var chatTextEmojiRegex = try? NSRegularExpression(pattern: #"(?<=:).*"#)
}

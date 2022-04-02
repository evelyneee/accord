//
//  String++.swift
//  Accord
//
//  Created by evelyn on 2022-03-06.
//

import Foundation

extension String {
    var hasEmojisOnly: Bool {
        var mut = trimmingCharacters(in: .whitespacesAndNewlines)
        let discordEmojis = mut
            .matchRange(precomputed: Regex.fullEmojiRegex)
        discordEmojis
            .reversed()
            .forEach { mut.removeSubrange($0) }
        return mut
            .filter { !$0.isEmoji }
            .count == 0
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

extension String {
    enum DataErrors: Error {
        case notString
    }

    init(_ data: Data) throws {
        let initialize = Self(data: data, encoding: .utf8)
        guard let initialize = initialize else { throw DataErrors.notString }
        self = initialize
    }

    var cString: UnsafePointer<CChar>? {
        let nsString = self as NSString
        return nsString.utf8String
    }
}

extension String {
    func makeProperDate() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        let date = formatter.date(from: self)
        guard let date = date else {
            return ""
        }
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    func makeProperHour() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        let date = formatter.date(from: self)
        guard let date = date else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        return dateFormatter.string(from: date)
    }
}

extension String {
    func matches(for regex: String? = nil, precomputed: NSRegularExpression? = nil) -> [String] {
        let regex = precomputed ?? (try? NSRegularExpression(pattern: regex!))
        let results = regex?.matches(in: self, range: NSRange(startIndex..., in: self))
        guard let mapped = results?.compactMap({ result -> String? in
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

    func matchRange(for regex: String? = nil, precomputed: NSRegularExpression? = nil) -> [Range<String.Index>] {
        let regex = precomputed ?? (try? NSRegularExpression(pattern: regex!))
        let results = regex?.matches(in: self, range: NSRange(startIndex..., in: self))
        guard let mapped = results?.compactMap({ Range($0.range, in: self) }) else {
            return []
        }
        return mapped
    }

    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = startIndex
        while startIndex < endIndex,
              let range = self[startIndex...].range(of: string, options: options)
        {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

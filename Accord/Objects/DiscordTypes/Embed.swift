//
//  Embed.swift
//  Accord
//
//  Created by evelyn on 2021-10-24.
//

import Foundation

final class Embed: Codable, Hashable, Identifiable {
    static func == (lhs: Embed, rhs: Embed) -> Bool {
        lhs.id == rhs.id
    }

    var title: String?
    var type: String?
    var description: String?
    var url: String?
    var timestamp: String?
    var color: Int?
    var image: Embed.Image?
    var thumbnail: Embed.Image?
    var video: Embed.Video?
    var provider: Embed.Provider?
    var author: Embed.Author?
    var fields: [Embed.Field]?
    var id: Int? { hashValue }

    func hash(into hasher: inout Hasher) {
        hasher.combine((timestamp ?? "") + (url ?? "") + (title ?? ""))
    }

    final class Field: Codable {
        var name: String
        var inline: Bool?
        var value: String
    }

    final class Author: Codable {
        var name: String
        var url: String?
        var icon_url: String?
        var proxy_icon_url: String?
    }

    final class Image: Codable {
        var url: String
        var proxy_url: String?
        var height: Int?
        var width: Int?
    }

    final class Video: Codable {
        var url: String?
        var proxy_url: String?
        var height: Int?
        var width: Int?
    }

    final class Provider: Codable {
        var name: String?
        var url: String?
    }
}

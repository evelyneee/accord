//
//  SongLink.swift
//  SongLink
//
//  Created by evelyn on 2021-09-17.
//

import Foundation

// MARK: - Base

struct SongLinkBase: Codable {
    let entityUniqueID: String?
    let userCountry: Country
    let pageURL: String
    let entitiesByUniqueID: [String: EntitiesByUniqueID]
    let linksByPlatform: LinksByPlatform

    enum CodingKeys: String, CodingKey {
        case entityUniqueID = "entityUniqueId"
        case userCountry
        case pageURL = "pageUrl"
        case entitiesByUniqueID = "entitiesByUniqueId"
        case linksByPlatform
    }
}

// MARK: - EntitiesByUniqueID

struct EntitiesByUniqueID: Codable {
    let id: String
    let type: TypeEnum
    let title: String
    let artistName: String
    let thumbnailURL: String?
    let thumbnailWidth, thumbnailHeight: Int
    let apiProvider: String
    let platforms: [String]

    enum CodingKeys: String, CodingKey {
        case id, type, title, artistName
        case thumbnailURL = "thumbnailUrl"
        case thumbnailWidth, thumbnailHeight, apiProvider, platforms
    }
}

enum TypeEnum: String, Codable {
    case song
}

// MARK: - LinksByPlatform

struct LinksByPlatform: Codable {
    let amazonMusic, amazonStore, deezer: AmazonMusic?
    let appleMusic, itunes: AppleMusic
    let napster, pandora, soundcloud, spotify: AmazonMusic?
    let tidal, yandex, youtube, youtubeMusic: AmazonMusic?
}

// MARK: - AmazonMusic

struct AmazonMusic: Codable {
    let country: Country
    let url: String
    let entityUniqueID: String
    let nativeAppURIDesktop: String?

    enum CodingKeys: String, CodingKey {
        case country, url
        case entityUniqueID = "entityUniqueId"
        case nativeAppURIDesktop = "nativeAppUriDesktop"
    }
}

enum Country: String, Codable {
    case ru = "RU"
    case us = "US"
}

// MARK: - AppleMusic

struct AppleMusic: Codable {
    let country: Country
    let url: String
    let nativeAppURIMobile, nativeAppURIDesktop, entityUniqueID: String

    enum CodingKeys: String, CodingKey {
        case country, url
        case nativeAppURIMobile = "nativeAppUriMobile"
        case nativeAppURIDesktop = "nativeAppUriDesktop"
        case entityUniqueID = "entityUniqueId"
    }
}

public enum Platforms: String, CaseIterable, Identifiable {
    case amazonMusic, amazonStore, deezer, appleMusic, itunes, napster, pandora, soundcloud, spotify, tidal, yandex, youtube, youtubeMusic
    public var id: String { rawValue }
}

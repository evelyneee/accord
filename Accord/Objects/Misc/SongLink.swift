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
    let pageURL: String
    let linksByPlatform: LinksByPlatform

    enum CodingKeys: String, CodingKey {
        case entityUniqueID = "entityUniqueId"
        case pageURL = "pageUrl"
        case linksByPlatform
    }
}

enum TypeEnum: String, Codable {
    case song
}

// MARK: - LinksByPlatform

struct LinksByPlatform: Codable {
    let appleMusic, itunes, spotify: Platform
}

// MARK: - AppleMusic

struct Platform: Codable {
    let url: String
    let nativeAppURIMobile, nativeAppURIDesktop: String?

    enum CodingKeys: String, CodingKey {
        case url
        case nativeAppURIMobile = "nativeAppUriMobile"
        case nativeAppURIDesktop = "nativeAppUriDesktop"
    }
}

public enum Platforms: String, RawRepresentable, CaseIterable, Identifiable {
    case amazonMusic, amazonStore, deezer, appleMusic, itunes, napster, pandora, soundcloud, spotify, tidal, yandex, youtube, youtubeMusic
    public var id: String { rawValue }
}

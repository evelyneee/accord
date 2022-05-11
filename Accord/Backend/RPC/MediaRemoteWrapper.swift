//
//  MediaRemoteWrapper.swift
//  Accord
//
//  Created by evelyn on 2021-12-28.
//

import Combine
import Foundation

// MARK: - SpotifyResponse
struct SpotifyResponse: Codable {
    let tracks: Tracks
}

// MARK: - Tracks
struct Tracks: Codable {
    let href: String
    let items: [SpotifyItem]
    let limit: Int
    let offset: Int
    let total: Int
}

// MARK: - Item
struct SpotifyItem: Codable {
    let album: Album
    let artists: [Artist]
    let availableMarkets: [String]
    let discNumber, durationMS: Int
    let explicit: Bool
    let externalUrls: ExternalUrls
    let href: String
    let id: String
    let isLocal: Bool
    let name: String
    let popularity: Int
    let trackNumber: Int
    let type, uri: String

    enum CodingKeys: String, CodingKey {
        case album, artists
        case availableMarkets = "available_markets"
        case discNumber = "disc_number"
        case durationMS = "duration_ms"
        case explicit
        case externalUrls = "external_urls"
        case href, id
        case isLocal = "is_local"
        case name, popularity
        case trackNumber = "track_number"
        case type, uri
    }
}

// MARK: - Album
struct Album: Codable {
    let albumType: String
    let artists: [Artist]
    let availableMarkets: [String]
    let externalUrls: ExternalUrls
    let href: String
    let id: String
    let images: [SpotifyImage]
    let name, releaseDate, releaseDatePrecision: String
    let totalTracks: Int
    let type, uri: String

    enum CodingKeys: String, CodingKey {
        case albumType = "album_type"
        case artists
        case availableMarkets = "available_markets"
        case externalUrls = "external_urls"
        case href, id, images, name
        case releaseDate = "release_date"
        case releaseDatePrecision = "release_date_precision"
        case totalTracks = "total_tracks"
        case type, uri
    }
}

// MARK: - Artist
struct Artist: Codable {
    let externalUrls: ExternalUrls
    let href: String
    let id, name, type, uri: String

    enum CodingKeys: String, CodingKey {
        case externalUrls = "external_urls"
        case href, id, name, type, uri
    }
}

// MARK: - ExternalUrls
struct ExternalUrls: Codable {
    let spotify: String
}

// MARK: - Image
struct SpotifyImage: Codable {
    let height: Int
    let url: String
    let width: Int
}

final class MediaRemoteWrapper {
    
    typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    
    static var MRMediaRemoteGetNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction = {
        // Load framework
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        // Get a Swift function for MRMediaRemoteGetNowPlayingInfo
        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { fatalError("Could not find symbol in MediaRemote image") }
        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
        return unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
    }()
    
    static var useSpotifyRPC: Bool = UserDefaults.standard.value(forKey: "SpotifyRPC") as? Bool ?? true
    
    final class Song {
        internal init(name: String, artist: String? = nil, duration: Double? = nil, albumName: String? = nil, elapsed: Double? = nil, isMusic: Bool, artworkURL: String?) {
            self.name = name
            self.artist = artist
            self.duration = duration
            self.albumName = albumName
            self.elapsed = elapsed
            self.isMusic = isMusic
            self.artworkURL = artworkURL
        }

        var name: String
        var artist: String?
        var duration: Double?
        var albumName: String?
        var elapsed: Double?
        var isMusic: Bool
        var artworkURL: String?
    }

    enum NowPlayingErrors: Error {
        case errorGettingNowInfoPtr
        case noName
    }

    /*
     1:
     assets:
        large_image: "spotify:ab67616d0000b27326f7f19c7f0381e56156c94a"
        large_text: "Graduation"
     details: "I Wonder"
     flags: 48
     metadata:
        album_id: "4SZko61aMnmgvNhfhgTuD3"
        artist_ids:["5K4W6rqBFWDnAN6FQUkS6x"]
     name: "Spotify"
     party: {
        id: "spotify:645775800897110047"
     }
     state: "Kanye West"
     sync_id: "7rbECVPkY5UODxoOUVKZnA"
     timestamps:
        end: 1652278715825
        start: 1652278472385
     type: 2
     */
    
    class func getCurrentlyPlayingSong() -> Future<Song, Error> {
        Future { promise in
            // Get song info
            MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { information in
                guard let name = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String else { return promise(.failure(NowPlayingErrors.noName)) }
                let isMusic = information["kMRMediaRemoteNowPlayingInfoIsMusicApp"] as? Bool ?? false
                let progress = information["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double
                if let id = (information["kMRMediaRemoteNowPlayingInfoAlbumiTunesStoreAdamIdentifier"] as? Int) ?? (information["kMRMediaRemoteNowPlayingInfoiTunesStoreIdentifier"] as? Int) {
                    print("Song has iTunes Store ID")
                    Request.fetch(url: URL(string: "https://itunes.apple.com/lookup?id=\(String(id))"), completion: { completion in
                        switch completion {
                        case let .success(data):
                            print("Success fetching iTunes Store ID")
                            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                let results = dict["results"] as? [[String: Any]] {
                                let artworkURL = results.first?["artworkUrl100"] as? String
                                let song = Song(
                                    name: name,
                                    artist: information["kMRMediaRemoteNowPlayingInfoArtist"] as? String,
                                    duration: information["kMRMediaRemoteNowPlayingInfoDuration"] as? Double,
                                    albumName: information["kMRMediaRemoteNowPlayingInfoAlbum"] as? String,
                                    elapsed: progress,
                                    isMusic: isMusic,
                                    artworkURL: artworkURL
                                )
                                promise(.success(song))
                            }
                        case let .failure(error):
                            print(error)
                        }
                    })
                } else {
                    print("where is da adam id??", information.keys)
                    let song = Song(
                        name: name,
                        artist: information["kMRMediaRemoteNowPlayingInfoArtist"] as? String,
                        duration: information["kMRMediaRemoteNowPlayingInfoDuration"] as? Double,
                        albumName: information["kMRMediaRemoteNowPlayingInfoAlbum"] as? String,
                        elapsed: progress,
                        isMusic: isMusic,
                        artworkURL: nil
                    )
                    promise(.success(song))
                }
            }
        }
    }

    static var bag = Set<AnyCancellable>()
    static var rateLimit: Bool = false
    static var status: String?

    class func updatePresence(status: String? = nil) {
        guard !Self.rateLimit else { return }
        rateLimit = true
        MediaRemoteWrapper.getCurrentlyPlayingSong()
            .sink(receiveCompletion: {
                switch $0 {
                case .finished: break
                case .failure(let error): print(error)
                }
            }, receiveValue: { song in
                guard song.isMusic else { return }
                if let spotifyToken = spotifyToken, Self.useSpotifyRPC {
                    Request.fetch(SpotifyResponse.self, url: URL.init(string: "https://api.spotify.com/v1/search?type=track&q=" + ((song.artist ?? "") + "+" + song.name).replacingOccurrences(of: " ", with: "+")), headers: Headers.init(
                        contentType: "application/json",
                        token: "Bearer " + spotifyToken,
                        type: .GET
                    )) {
                        switch $0 {
                        case .success(let packet):
                            try? wss.updatePresence(status: status ?? Self.status ?? "dnd", since: 0) {
                                Activity.current!
                                Activity(
                                    flags: 48,
                                    name: "Spotify",
                                    type: 2,
                                    metadata: ["album_id":packet.tracks.items.first?.album.id ?? "", "artist_ids":packet.tracks.items.first?.artists.map(\.id) ?? []],
                                    timestamp: Int(Date().timeIntervalSince1970) * 1000,
                                    endTimestamp: song.duration != nil ? Int(Date().timeIntervalSince1970 + (song.duration!)) * 1000 : nil,
                                    state: song.artist ?? "Unknown artist",
                                    details: song.name,
                                    assets: [
                                        "large_image": "spotify:\(packet.tracks.items.first?.album.images.first?.url.components(separatedBy: "/").last ?? "")",
                                        "large_text": song.albumName ?? "Unknown album",
                                    ]
                                )
                            }
                        case .failure(let error):
                            print(error)
                        }
                    }
                } else if let url = song.artworkURL {
                    ExternalImages.proxiedURL(appID: musicRPCAppID, url: url)
                        .replaceError(with: [])
                        .sink { out in
                            print(song.duration)
                            guard let url = out.first?.external_asset_path else { return }
                            try? wss.updatePresence(status: status ?? Self.status ?? "dnd", since: 0) {
                                Activity.current!
                                Activity(
                                    flags: 48,
                                    name: "Apple Music",
                                    type: 2,
                                    timestamp: Int(Date().timeIntervalSince1970) * 1000,
                                    endTimestamp: song.duration != nil ? Int(Date().timeIntervalSince1970 + (song.duration!)) * 1000 : nil,
                                    state: song.albumName ?? song.name + " (Single)",
                                    details: song.name,
                                    assets: [
                                        "large_image": "mp:\(url)",
                                        "large_text": song.albumName ?? "Unknown album",
                                    ]
                                )
                            }
                        }
                        .store(in: &bag)
                } else {
                    try? wss.updatePresence(status: status ?? Self.status ?? "dnd", since: 0) {
                        Activity.current!
                        Activity(
                            applicationID: musicRPCAppID,
                            flags: 1,
                            name: "Apple Music",
                            type: 2,
                            timestamp: Int(Date().timeIntervalSince1970) * 1000,
                            state: "In \(song.albumName ?? song.name) by \(song.artist ?? "someone")",
                            details: song.name
                        )
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    rateLimit = false
                }
            })
            .store(in: &Self.bag)
    }
}

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
    
    class func getCurrentlyPlayingSong() -> Future<Song, Error> {
        Future { promise in
            // Get song info
            MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { information in
                guard let name = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String else { return promise(.failure(NowPlayingErrors.noName)) }
                let isMusic = information["kMRMediaRemoteNowPlayingInfoIsMusicApp"] as? Bool ?? false
                let timestamp = information["kMRMediaRemoteNowPlayingInfoTimestamp"] as? String
                let formatted = Date().timeIntervalSince1970 - (ISO8601DateFormatter().date(from: timestamp ?? "")?.timeIntervalSince1970 ?? 0)
                let progress = (information["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double) ?? formatted
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

    class private func updateWithSong(_ song: Song) {
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
    
    class private func updateWithArtworkURL(_ song: Song, artworkURL: String) {
        ExternalImages.proxiedURL(appID: musicRPCAppID, url: artworkURL)
            .replaceError(with: [])
            .sink { out in
                guard let url = out.first?.external_asset_path else { return }
                try? wss.updatePresence(status: status ?? Self.status ?? "dnd", since: 0) {
                    Activity.current!
                    Activity(
                        flags: 1,
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
    }
    
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
                            if let track = packet.tracks.items.first, let imageURL = track.album.images.first?.url.components(separatedBy: "/").last {
                                print(song.elapsed)
                                try? wss.updatePresence(status: status ?? Self.status ?? "dnd", since: 0) {
                                    Activity.current!
                                    Activity(
                                        flags: 48,
                                        name: "Spotify",
                                        type: 2,
                                        metadata: ["album_id":track.album.id, "artist_ids":track.artists.map(\.id)],
                                        timestamp: Int(Date().timeIntervalSince1970 - (song.elapsed ?? 0)) * 1000,
                                        endTimestamp: Int(Date().timeIntervalSince1970 + (song.duration ?? Double(track.durationMS / 1000))) * 1000,
                                        state: song.artist ?? "Unknown artist",
                                        details: track.name,
                                        assets: [
                                            "large_image": "spotify:"+imageURL,
                                            "large_text": track.album.name,
                                        ]
                                    )
                                }
                            } else if let url = song.artworkURL {
                                Self.updateWithArtworkURL(song, artworkURL: url)
                            } else {
                                Self.updateWithSong(song)
                            }
                        case .failure(let error):
                            print(error)
                        }
                    }
                } else if let url = song.artworkURL {
                    Self.updateWithArtworkURL(song, artworkURL: url)
                } else {
                    Self.updateWithSong(song)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    rateLimit = false
                }
            })
            .store(in: &Self.bag)
    }
}

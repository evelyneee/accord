//
//  MediaRemoteWrapper.swift
//  Accord
//
//  Created by evelyn on 2021-12-28.
//

import Combine
import Foundation

final class MediaRemoteWrapper {
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

    static let appID: String = "925514277987704842"

    class func getCurrentlyPlayingSong() -> Future<Song, Error> {
        Future { promise in
            // Load framework
            let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

            // Get a Swift function for MRMediaRemoteGetNowPlayingInfo
            guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return promise(.failure(NowPlayingErrors.errorGettingNowInfoPtr)) }
            typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
            let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

            // Get song info
            MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { information in
                guard let name = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String else { return promise(.failure(NowPlayingErrors.noName)) }
                let isMusic = information["kMRMediaRemoteNowPlayingInfoIsMusicApp"] as? Bool ?? false
                let progress = information["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double
                print("done")
                if let id = information["kMRMediaRemoteNowPlayingInfoAlbumiTunesStoreAdamIdentifier"] as? Int {
                    Request.fetch(url: URL(string: "https://itunes.apple.com/lookup?id=\(String(id))"), completion: { data, error in
                        if let data = data, let dict = try? JSONSerialization.jsonObject(with: data) as? [String:Any] ?? [:] {
                            let artworkURL = (dict["results"] as? [[String:Any]])?.first?["artworkUrl100"] as? String
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
                    })
                } else {
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
            .sink(receiveCompletion: { _ in

            }, receiveValue: { song in
                guard song.isMusic else { return }
                if let url = song.artworkURL {
                    ExternalImages.proxiedURL(appID: musicRPCAppID, url: url)
                        .replaceError(with: [])
                        .sink { out in
                            guard let url = out.first?.external_asset_path else { return }
                            try? wss.updatePresence(status: status ?? Self.status ?? "dnd", since: 0) {
                                Activity.current!
                                Activity(
                                    applicationID: "925514277987704842",
                                    flags: 1,
                                    name: "Apple Music",
                                    type: 0,
                                    timestamp: Int(Date().timeIntervalSince1970) * 1000,
                                    state: "Listening to \(song.artist ?? "someone")",
                                    details: "\(song.name)\(song.albumName != nil ? " - \(song.albumName!)": "")",
                                    assets: [
                                        "large_image":"mp:\(url)",
                                        "large_text":song.albumName ?? song.name
                                    ]
                                )
                            }
                        }
                        .store(in: &bag)
                } else {
                    try? wss.updatePresence(status: status ?? Self.status ?? "dnd", since: 0) {
                        Activity.current!
                        Activity(
                            applicationID: "925514277987704842",
                            flags: 1,
                            name: "Apple Music",
                            type: 0,
                            timestamp: Int(Date().timeIntervalSince1970) * 1000,
                            state: "Listening to \(song.artist ?? "someone")",
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


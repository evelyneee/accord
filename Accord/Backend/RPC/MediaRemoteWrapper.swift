//
//  MediaRemoteWrapper.swift
//  Accord
//
//  Created by evelyn on 2021-12-28.
//

import Foundation
import Combine

final class MediaRemoteWrapper {
    final class Song {
        internal init(name: String, artist: String? = nil, duration: Double? = nil, albumName: String? = nil, elapsed: Double? = nil, isMusic: Bool) {
            self.name = name
            self.artist = artist
            self.duration = duration
            self.albumName = albumName
            self.elapsed = elapsed
            self.isMusic = isMusic
        }
        
        var name: String
        var artist: String?
        var duration: Double?
        var albumName: String?
        var elapsed: Double?
        var isMusic: Bool
    }
    
    enum NowPlayingErrors: Error, LocalizedError, CustomStringConvertible {
        case errorGettingNowInfoPtr
        case noName
        
        public var description: String {
            switch self {
            case .errorGettingNowInfoPtr:
                return "An error occured while getting \"Now Playing\" info"
            case .noName:
                return "Couldn't get the name of the Song currently playing"
            }
        }
        
        public var errorDescription: String? {
            return description
        }
    }
    
    static let appID: String = "925514277987704842"
    
    class func getCurrentlyPlayingSong() -> Future<Song, Error> {
        Future { promise in
            // Load framework
            let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

            // Get a Swift function for MRMediaRemoteGetNowPlayingInfo
            guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return promise(.failure(NowPlayingErrors.errorGettingNowInfoPtr))}
            typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
            let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

            // Get song info
            MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (information) in
                guard let name = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String else { return promise(.failure(NowPlayingErrors.noName)) }
                let isMusic = information["kMRMediaRemoteNowPlayingInfoIsMusicApp"] as! Bool
                let progress = information["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double
                let song = Song(
                    name: name,
                    artist: information["kMRMediaRemoteNowPlayingInfoArtist"] as? String,
                    duration: information["kMRMediaRemoteNowPlayingInfoDuration"] as? Double,
                    albumName: information["kMRMediaRemoteNowPlayingInfoAlbum"] as? String,
                    elapsed: progress,
                    isMusic: isMusic
                )
                promise(.success(song))
            })
        }
    }
    
    static var bag = Set<AnyCancellable>()
    static var rateLimit: Bool = false
    static var status: String? = nil
    
    class func updatePresence(status: String? = nil) {
        guard !Self.rateLimit else { return }
        rateLimit = true
        MediaRemoteWrapper.getCurrentlyPlayingSong()
            .sink(receiveCompletion: { c in
                
            }, receiveValue: { song in
                guard song.isMusic else { return }
                try? wss.updatePresence(status: status ?? Self.status ?? "dnd", since: 0) {
                    Activity.current!
                    Activity(
                        applicationID: "925514277987704842",
                        flags: 1,
                        name: "Apple Music",
                        type: 0,
                        timestamp: Int(Date().timeIntervalSince1970) * 1000,
                        state: "Listening to \(song.artist ?? "cock")",
                        details: song.name
                    )
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    rateLimit = false
                })
            })
            .store(in: &Self.bag)
    }
}


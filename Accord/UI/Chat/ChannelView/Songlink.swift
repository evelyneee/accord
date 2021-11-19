//
//  Songlink.swift
//  Songlink
//
//  Created by evelyn on 2021-09-17.
//

import Foundation
import SwiftUI

final class SongLink {
    static var shared = SongLink()
    
    final func parseLink(link: String) -> String? {
        var ret: String? = nil
        switch URL(string: link)?.host {
        case "music.apple.com": break
        case "spotify.com": ret = parseSpotifyLink(link: link); break
        default: break
        }
        return ret
    }
    
    // MARK: - Get song id
    final func parseSpotifyLink(link: String) -> String {
        let comp = link.components(separatedBy: "/").last
        return "spotify:track:\(comp?.description.components(separatedBy: "?").first ?? "")"
    }
    
    /*
     Testing link:
     https://music.apple.com/ca/album/i-almost-do-taylors-version/1590368448?i=1590368458
     */
    
    func test() {
        guard let id = parseAppleMusicLink(link: "https://music.apple.com/ca/album/i-almost-do-taylors-version/1590368448?i=1590368458") else {
            fatalError("[SongLink Tests] ID not parsed")
        }
        print(id)
        getSong(song: id, completion: { song in
            if let song = song {
                print(song.pageURL)
            }
        })
    }
    
    final func parseAppleMusicLink(link: String) -> String? {
        let slashed = link.components(separatedBy: "/").last
        guard let interrogated = slashed?.components(separatedBy: "?").first else { return nil }
        return String("appleMusic:track:\(interrogated)")
    }
    
    #warning("TODO: Other platform parsers")
    
    // MARK: - Song getter
    final func getSong(song: String, completion: @escaping ((SongLinkBase?) -> Void)) {
        guard let encoded = song.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
        let url = URL(string: "https://api.song.link/v1-alpha.1/links?url=\(encoded)") else { print("ripbozo"); return completion(nil) }
        print(url)
        Request.fetch(SongLinkBase.self, url: url, headers: Headers(type: .GET)) { songLink, error in
            if let songLink = songLink {
                return completion(songLink)
            } else if let error = error {
                print(error)
            }
        }
    }
}

extension Substring {
    func str() -> String { String(self) }
}

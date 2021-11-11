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
    
    #warning("TODO: Other platform parsers")
    
    // MARK: - Song getter
    final func getSong(song: String, completion: @escaping ((SongLinkBase?) -> Void)) {
        Request.fetch(SongLinkBase.self, url: URL(string: "https://api.song.link/v1-alpha.1/links?url=\(self.parseSpotifyLink(link: song).addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")&userCountry=US"), headers: Headers(type: .GET)) { songLink in
            if let songLink = songLink {
                return completion(songLink)
            }
        }
    }
}

extension Substring {
    func str() -> String { String(self) }
}

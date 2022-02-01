//
//  Songlink.swift
//  Songlink
//
//  Created by evelyn on 2021-09-17.
//

import Foundation
import SwiftUI

final class SongLink {
    // MARK: - Song getter

    public class func getSong(song: String, completion: @escaping ((SongLinkBase?) -> Void)) {
        guard let encoded = song.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let url = URL(string: "https://api.song.link/v1-alpha.1/links?url=\(encoded)") else { print("ripbozo"); return completion(nil) }
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
    var stringLiteral: String {
        String(self)
    }
}

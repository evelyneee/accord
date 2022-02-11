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

    public class func getSong(song: String, block: @escaping ((SongLinkBase?) -> Void)) {
        guard let encoded = song.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let url = URL(string: "https://api.song.link/v1-alpha.1/links?url=\(encoded)") else { print("ripbozo"); return block(nil) }
        Request.fetch(SongLinkBase.self, url: url, headers: Headers(type: .GET)) { completion in
            switch completion {
            case .success(let value):
                return block(value)
            case .failure(let error):
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

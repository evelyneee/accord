//
//  Images.swift
//  Accord
//
//  Created by evelyn on 2021-06-14.
//

import Foundation
import AppKit

final class ImageHandling {
    let cache = URLCache.shared
    static var shared = ImageHandling()
    func getAllProfilePictures(array: [Message]) -> [String:NSImage] {
        let pfpURLs = array.map {
            "https://cdn.discordapp.com/avatars/\($0.author.id )/\($0.author.avatar ?? "").png?size=80"
        }
        var singleURLs: [String] = []
        var returnArray: [String:NSImage] = [:]
        for url in pfpURLs {
            if !(singleURLs.contains(url)) {
                if !(url.contains("<null>")) {
                    singleURLs.append(url)
                }
            }
        }
        for url in singleURLs {
            let userid = String((String(url.dropFirst(35))).prefix(18))
            if let url = URL(string: url) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 20.0)
                if let data = cache.cachedResponse(for: request)?.data {
                    returnArray[String(userid)] = NSImage(data: data)
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            self.cache.storeCachedResponse(cachedData, for: request)
                            DispatchQueue.main.async {
                                returnArray[String(userid)] = NSImage(data: data)
                            }
                        }
                    }).resume()
                }
            }
        }
        return returnArray
    }
}


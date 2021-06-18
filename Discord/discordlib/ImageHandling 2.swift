//
//  ImageHandling.swift
//  Helselia
//
//  Created by evelyn on 2021-06-14.
//

import Foundation
import AppKit

final class ImageHandling {
    static var shared = ImageHandling()
    func getAllProfilePictures(array: [[String:Any]]) -> [String:NSImage] {
        let pfpURLs = parser.getArray(forKey: "avatar", messageDictionary: array)
        var singleURLs: [String] = []
        var returnArray: [String:NSImage] = [:]
        for url in pfpURLs {
            if let urlstr = url as? String {
                if !(singleURLs.contains(urlstr)) {
                    if !(urlstr.contains("<null>")) {
                        singleURLs.append(urlstr)
                    }
                }
            }
        }
        for url in singleURLs {
            let userid = String((String(url.dropFirst(35))).prefix(18))
            let cache = URLCache.shared
            if let url = URL(string: url) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 20.0)
                if let data = cache.cachedResponse(for: request)?.data {
                    returnArray[String(userid)] = NSImage(data: data)
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                                            cache.storeCachedResponse(cachedData, for: request)
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

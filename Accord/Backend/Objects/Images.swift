//
//  Images.swift
//  Accord
//
//  Created by evelyn on 2021-06-14.
//

import Foundation
import AppKit

final class ImageHandling {
    static var shared: ImageHandling? = ImageHandling()
    let cache: URLCache? = URLCache.shared
    func getProfilePictures(array: [Message], _ completion: @escaping ((_ success: Bool, _ pfps: [String:NSImage]) -> Void)) {
        let pfpURLs = array.map {
            "https://cdn.discordapp.com/avatars/\($0.author?.id ?? "")/\($0.author?.avatar ?? "").png?size=80"
        }
        print(pfpURLs)
        var singleURLs: [String] = []
        var returnArray: [String:NSImage] = [:] {
            didSet {
                print("DONE \(returnArray.count)")
                if returnArray.count == singleURLs.count {
                    print("GOODBYE \(returnArray.count)")
                    return completion(true, returnArray)
                }
            }
        }
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
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                if let data = cache?.cachedResponse(for: request)?.data {
                    returnArray[String(userid)] = NSImage(data: data)
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            self?.cache?.storeCachedResponse(cachedData, for: request)
                            returnArray[String(userid)] = NSImage(data: data)
                        }
                    }).resume()
                }
            }
        }
        return completion(false, [:])
    }
    func getServerIcons(array: [[String:Any]], _ completion: @escaping ((_ success: Bool, _ icons: [String:NSImage]) -> Void)) {
        let pfpURLs = array.compactMap {
            "https://cdn.discordapp.com/icons/\($0["id"] ?? "")/\($0["icon"] ?? "")"
        }
        var singleURLs: [String] = []
        var returnArray: [String:NSImage] = [:] {
            didSet {
                print("DONE \(returnArray.count)")
                if returnArray.count == singleURLs.count {
                    print("GOODBYE \(returnArray.count)")
                }
            }
        }
        for url in pfpURLs {
            if !(singleURLs.contains(url)) {
                if !(url.contains("<null>")) {
                    singleURLs.append(url)
                }
            }
        }
        print(singleURLs)
        for url in singleURLs {
            let userid = String((String(url.dropFirst(33))).prefix(18))
            if let url = URL(string: url) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 30.0)
                if let data = cache?.cachedResponse(for: request)?.data {
                    returnArray[String(userid)] = NSImage(data: data)
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            self?.cache?.storeCachedResponse(cachedData, for: request)
                            returnArray[String(userid)] = NSImage(data: data)
                        }
                    }).resume()
                }
            }
            if url == singleURLs[singleURLs.count - 1] {
                return completion(true, returnArray)
            }
        }
    }

    init(_ empty:Bool = false) {
        print("loaded pfpmanager")
    }
    deinit {
        print("IF THIS NEVER SHOWS, FUCK")
    }
}


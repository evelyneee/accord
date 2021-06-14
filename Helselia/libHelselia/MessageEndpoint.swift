//
//  MessageEndpoint.swift
//  Helselia
//
//  Created by evelyn on 2021-03-07.
//

import Foundation
import SwiftUI

final class ParseMessages {
    static var shared = ParseMessages()
    func getItem(forKey: String, secondary: Bool, secondaryItem: String, messageDictionary: [[String:Any]], position: Int) -> Any {
        var returnItem: Any = ""
        for item in messageDictionary[position].keys {
            if item == forKey {
                returnItem = messageDictionary[position][item] ?? ""
                break
            } else {
                returnItem = "Key Not Found In Item."
            }
        }
        if secondary == true {
            if type(of: returnItem) == Dictionary<String, Any>.self {
                for i in (returnItem as! Dictionary<String, Any>).keys {
                    if i == secondaryItem {
                        returnItem = secondaryItem
                    }
                }
            }
        }
        return returnItem
    }
    func getArray(forKey: String, messageDictionary: [[String:Any]]) -> [Any] {
        var returnItem: [Any] = []
        for message in messageDictionary {
            for item in message.keys {
                if item == forKey {
                    if forKey == "author" {
                        returnItem.append("\((message[item] as! Dictionary<String, Any>)["username"] ?? "error")#\((message[item] as! Dictionary<String, Any>)["discriminator"] ?? "0000")" )
                    } else {
                        returnItem.append(message[item] ?? "")
                    }
                } else if forKey == "avatar" && item == "author" {
                    returnItem.append("https://cdn.constanze.live/avatars/\((message[item] as! Dictionary<String, Any>)["id"] ?? "error")/\((message[item] as! Dictionary<String, Any>)["avatar"] ?? "error").png")
                } else if forKey == "user_id" && item == "author" {
                    returnItem.append((message[item] as! Dictionary<String, Any>)["id"] ?? "error")
                }
            }
        }
        return returnItem
    }
}

struct ImageWithURL: View {
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        #if os(iOS)
        Image(uiImage: (UIImage(data: self.imageLoader.imageData) ?? UIImage(named: "")) ?? UIImage())
              .resizable()
              .clipped()
        #else
        Image(nsImage: (NSImage(data: self.imageLoader.imageData) ?? NSImage(named: "")) ?? NSImage())
              .resizable()
              .clipped()
        #endif
    }
}

class ImageLoaderAndCache: ObservableObject {
    
    @Published var imageData = Data()
    
    init(imageURL: String) {
        let cache = URLCache.shared
        if let url = URL(string: imageURL) as? URL {
            let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 20.0)
            if let data = cache.cachedResponse(for: request)?.data {
                self.imageData = data
            } else {
                URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                    if let data = data, let response = response {
                    let cachedData = CachedURLResponse(response: response, data: data)
                                        cache.storeCachedResponse(cachedData, for: request)
                        DispatchQueue.main.async {
                            self.imageData = data
                        }
                    }
                }).resume()
            }
        }
    }
}

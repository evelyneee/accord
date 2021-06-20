//
//  Messages.swift
//  Accord
//
//  Created by evelyn on 2021-03-07.
//

import Foundation
import SwiftUI

final class ParseMessages {
    static var shared = ParseMessages()
    
    func getArray(forKey: String, messageDictionary: [[String:Any]]) -> [Any] {
        var returnItem: [Any] = []
        for message in messageDictionary {
            switch forKey {
            case "author":
                returnItem.append("\((message["author"] as? Dictionary<String, Any> ?? [:])["username"] ?? "error")#\((message["author"] as? Dictionary<String, Any> ?? [:])["discriminator"] ?? "0000")" )
            case "avatar":
                returnItem.append("https://cdn.discordapp.com/avatars/\((message["author"] as? Dictionary<String, Any> ?? [:])["id"] as? String ?? "")/\((message["author"] as? Dictionary<String, Any> ?? [:])["avatar"] as? String ?? "").png?size=80")
            case "user_id":
                returnItem.append((message["author"] as? Dictionary<String, Any> ?? [:])["id"] ?? "error")
            default:
                returnItem.append(message[forKey] ?? "")
            }
        }
        return returnItem
    }
}

final class PrivateMessages {
    static var shared = PrivateMessages()
    func reorderPMs(array: [[String:Any]]) -> [[String:Any]] {
        print(array[0])
        print("PMS")
        return []
    }
}

struct ImageWithURL: View {
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: (NSImage(data: self.imageLoader.imageData) ?? NSImage(named: "")) ?? NSImage())
              .resizable()
              .clipped()
    }
}

struct Attachment: View {
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: (NSImage(data: self.imageLoader.imageData) ?? NSImage(named: "")) ?? NSImage())
              .resizable()
              .scaledToFit()
    }
}

class ImageLoaderAndCache: ObservableObject {
    
    @Published var imageData = Data()
    
    init(imageURL: String) {
        net.requestData(url: imageURL, token: nil, json: false, type: .GET, bodyObject: [:]) { success, data in
            if success {
                DispatchQueue.main.async {
                    self.imageData = data ?? Data()
                }
            }
        }
    }
}

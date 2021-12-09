//
//  Images.swift
//  Accord
//
//  Created by evelyn on 2021-06-14.
//

import Foundation
import AppKit
import SwiftUI
import Combine

final class ImageHandling {
    static var shared: ImageHandling? = ImageHandling()
    func getProfilePictures(array: [Message], _ completion: @escaping ((_ success: Bool, _ pfps: [String:NSImage]) -> Void)) {
        let pfpURLs = array.compactMap { (elem) -> String? in
            guard let avi = elem.author?.avatar else { return nil }
            return "https://cdn.discordapp.com/avatars/\(elem.author!.id)/\(avi).png?size=80"
        }
        var returnArray: [String:NSImage] = [:]
        for url in pfpURLs {
            let userid = String((String(url.dropFirst(35))).prefix(18))
            if let url = URL(string: url) {
                Request.image(url: url) { image in
                    if let image = image {
                        returnArray[String(userid)] = image
                    }
                }
            }
        }
        return completion(false, [:])
    }
    func sendRequest(url: String) -> Data? {
        var dataReceived: Data?
        let sem = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        let session = URLSession(configuration: config)
        if let url = URL(string: url) {
            var request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 30.0)
            request.httpMethod = "GET"
            if let data = cache.cachedResponse(for: request)?.data {
                DispatchQueue.main.async {
                    dataReceived = data
                    sem.signal()
                }
            } else {
                session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if let data = data, let response = response {
                    let cachedData = CachedURLResponse(response: response, data: data)
                        cache.storeCachedResponse(cachedData, for: request)
                        DispatchQueue.main.async {
                            dataReceived = data
                            sem.signal()
                        }
                    } else  {
                        print(error?.localizedDescription ?? "")
                    }
                }).resume()
            }
        } else {
            sem.signal()
        }
        sem.wait()
        return dataReceived
    }
    func getServerIcons(array: [Guild], _ completion: @escaping ((_ success: Bool, _ icons: [String:NSImage]) -> Void)) {
        let pfpURLs = array.compactMap { (elem) -> String? in
            guard let avi = elem.icon else { return nil }
            return "https://cdn.discordapp.com/icons/\(elem.id)/\(avi).png?size=80"
        }
        var returnArray: [String:NSImage] = [:]
        for url in pfpURLs {
            let userid = String((String(url.dropFirst(33))).prefix(18))
            if let url = URL(string: url) {
                Request.image(url: url) { image in
                    if let image = image {
                        returnArray[String(userid)] = image
                    }
                }
            }
        }
        return completion(true, returnArray)
    }

    init(_ empty:Bool = false) {
        print("loaded pfpmanager")
    }
}


let cachesURL: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
let diskCacheURL = cachesURL.appendingPathComponent("DownloadCache")
let cache = URLCache(memoryCapacity: 1_000_000_000, diskCapacity: 1_000_000_000, directory: diskCacheURL)

struct ImageWithURL: View, Equatable {
    static func == (lhs: ImageWithURL, rhs: ImageWithURL) -> Bool {
        return true
    }
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        HStack {
            Image(nsImage: imageLoader.image)
                  .resizable()
                  .clipped()
        }

    }
}

struct Attachment: View, Equatable {
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.url == rhs.url
    }
    
    @ObservedObject var imageLoader: ImageLoaderAndCache
    var url: String
    
    init(_ url: String, size: CGSize? = nil) {
        self.url = url
        imageLoader = ImageLoaderAndCache(imageURL: url, size: size)
    }

    var body: some View {
        Image(nsImage: imageLoader.image)
              .resizable()
              .scaledToFit()
    }
}

struct StockAttachment: View, Equatable {
    static func == (lhs: StockAttachment, rhs: StockAttachment) -> Bool {
        return true
    }
    
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: imageLoader.image)
              .resizable()
              .scaledToFit()

    }

}

struct HoveredAttachment: View, Equatable {
    
    static func == (lhs: HoveredAttachment, rhs: HoveredAttachment) -> Bool {
        return true
    }
    
    @ObservedObject var imageLoader: ImageLoaderAndCache
    @State var hovering = false
    
    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: imageLoader.image)
              .resizable()
              .scaledToFit()
              .padding(2)
              .background(hovering ? Color.gray.opacity(0.75).cornerRadius(1) : Color.clear.cornerRadius(0))
              .onHover(perform: { _ in
                  hovering.toggle()
              })
    }
}

let imageQueue = DispatchQueue(label: "ImageQueue", attributes: .concurrent)

final class ImageLoaderAndCache: ObservableObject {
    
    @Published var image: NSImage = NSImage()
    private var cancellable: AnyCancellable? = nil
    
    init(imageURL: String, size: CGSize? = nil) {
        guard let url = URL(string: imageURL) else { return }
        imageQueue.async {
            self.cancellable = RequestPublisher.image(url: url, to: size)
                .replaceError(with: NSImage())
                .replaceNil(with: NSImage())
                .receive(on: RunLoop.main)
                .assign(to: \.image, on: self)
        }
    }
}




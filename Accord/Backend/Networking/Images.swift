//
//  Images.swift
//  Accord
//
//  Created by evelyn on 2021-06-14.
//

import Foundation
import AppKit
import SwiftUI

final class ImageHandling {
    static var shared: ImageHandling? = ImageHandling()
    func getProfilePictures(array: [Message], _ completion: @escaping ((_ success: Bool, _ pfps: [String:NSImage]) -> Void)) {

        let pfpURLs = array.map {
            "https://cdn.discordapp.com/avatars/\($0.author!.id)/\($0.author?.avatar ?? "").png?size=80"
        }
        print(pfpURLs)
        var singleURLs: [String] = []
        var returnArray: [String:NSImage] = [:] {
            didSet {
                if returnArray.count == singleURLs.count {
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
                if let data = cache.cachedResponse(for: request)?.data {
                    returnArray[String(userid)] = NSImage(data: data)
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache.storeCachedResponse(cachedData, for: request)
                            returnArray[String(userid)] = NSImage(data: data)
                        }
                    }).resume()
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
            let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
            if let data = cache.cachedResponse(for: request)?.data {
                DispatchQueue.main.async {
                    print("cached")
                    dataReceived = data
                    sem.signal()
                }
            } else {
                session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if let data = data, let response = response {
                    let cachedData = CachedURLResponse(response: response, data: data)
                        cache.storeCachedResponse(cachedData, for: request)
                        DispatchQueue.main.async {
                            print(" havenwork")
                            dataReceived = data
                            sem.signal()
                        }
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
        let pfpURLs = array.compactMap {
            "https://cdn.discordapp.com/icons/\($0.id)/\($0.icon ?? "")?size=80"
        }
        var singleURLs: [String] = []
        var returnArray: [String:NSImage] = [:] {
            didSet {
                if returnArray.count == singleURLs.count {
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
        let _ = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { timer in
            return completion(true, returnArray)
        }
        print(singleURLs)
        for url in singleURLs {
            let userid = String((String(url.dropFirst(33))).prefix(18))
            if let url = URL(string: url) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 5.0)
                if let data = cache.cachedResponse(for: request)?.data {
                    returnArray[String(userid)] = NSImage(data: data)
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache.storeCachedResponse(cachedData, for: request)
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
        print("[Accord] loaded pfpmanager")
    }
    deinit {
        print("[Accord] IF THIS NEVER SHOWS, FUCK")
    }
}


let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
let diskCacheURL = cachesURL.appendingPathComponent("DownloadCache")
let cache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 1_000_000_000, directory: diskCacheURL)

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
            Image(nsImage: (NSImage(data: imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0))))
                  .resizable()
                  .clipped()
        }

    }
}

struct Attachment: View, Equatable {
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return true
    }
    
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: NSImage(data: imageLoader.imageData)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 400, height: 300)) ?? NSImage(size: NSSize(width: 0, height: 0)))
              .resizable()
              .scaledToFit()
              .onDisappear {
                  imageLoader.imageData = Data()
              }
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
        Image(nsImage: NSImage(data: imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0)))
              .resizable()
              .scaledToFit()
              .padding(2)
              .background(hovering ? Color.gray.opacity(0.75).cornerRadius(1) : Color.clear.cornerRadius(0))
              .onDisappear {
                  imageLoader.imageData = Data()
              }
              .onHover(perform: { _ in
                  hovering.toggle()
              })
    }
}

final class ImageLoaderAndCache: ObservableObject {
    
    @Published var imageData = Data()
    let imageQueue = DispatchQueue(label: "ImageQueue", attributes: .concurrent)

    init(imageURL: String) {
        imageQueue.async { [weak self] in
            let config = URLSessionConfiguration.default
            config.urlCache = cache
            let session = URLSession(configuration: config)

            if let url = URL(string: imageURL) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                if let data = cache.cachedResponse(for: request)?.data {
                    DispatchQueue.main.async {
                        print("cached")
                        self?.imageData = data
                    }
                } else {
                    session.dataTask(with: request, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache.storeCachedResponse(cachedData, for: request)
                            DispatchQueue.main.async {
                                print("network")
                                self?.imageData = data
                            }
                        }
                    }).resume()
                }
            }
        }

    }
    
    deinit {
        print("[Accord] unloaded image")
    }
}




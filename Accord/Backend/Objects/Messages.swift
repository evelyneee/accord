//
//  Messages.swift
//  Accord
//
//  Created by evelyn on 2021-03-07.
//

import Foundation
import SwiftUI

let cache: URLCache? = URLCache.shared
let imageQueue = DispatchQueue(label: "ImageQueue")

struct ImageWithURL: View {
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: (NSImage(data: imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0))))
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
        Image(nsImage: (NSImage(data: imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0))))
              .resizable()
              .scaledToFit()
              .onDisappear {
                  imageLoader.imageData = Data()
              }
    }

}

class ImageLoaderAndCache: ObservableObject {
    
    @Published var imageData = Data()

    init(imageURL: String) {
        imageQueue.async {
            if let url = URL(string: imageURL) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                if let data = cache?.cachedResponse(for: request)?.data {
                    DispatchQueue.main.async {
                        self.imageData = data
                    }
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache?.storeCachedResponse(cachedData, for: request)
                            DispatchQueue.main.async {
                                self?.imageData = data
                            }
                        }
                    }).resume()
                }
            }
        }

    }
    
    deinit {
        print("unloaded image")
    }
}


func getImage(url: String) -> Data {
    var ret: Data = Data()
    NetworkHandling.shared?.requestData(url: url, token: nil, json: false, type: .GET, bodyObject: [:]) { success, data in
        if (success) {
            ret = data ?? Data()
        }
    }
    return ret
}

func sendRequest(url: String) -> Data? {
    let session = URLSession.shared
    var dataReceived: Data?
    let sem = DispatchSemaphore(value: 0)
    if let url = URL(string: url) {
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            defer { sem.signal() }

            if let error = error {
                return
            }
            dataReceived = data as Data?
        }

        task.resume()

        // This line will wait until the semaphore has been signaled
        // which will be once the data task has completed
        sem.wait(timeout: DispatchTime.distantFuture)
        return dataReceived
    } else {
        return Data()
    }
}

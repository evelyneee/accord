//
//  Messages.swift
//  Accord
//
//  Created by evelyn on 2021-03-07.
//

import Foundation
import SwiftUI

let cache: URLCache? = URLCache.shared

struct ImageWithURL: View {
    
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

struct Attachment: View {
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: (NSImage(data: imageLoader.imageData)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 400, height: 300)) ?? NSImage(size: NSSize(width: 0, height: 0))))
              .resizable()
              .scaledToFit()
              .onDisappear {
                  imageLoader.imageData = Data()
              }
    }

}

struct HoveredAttachment: View {
    
    @ObservedObject var imageLoader: ImageLoaderAndCache
    @State var hovering = false
    
    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: (NSImage(data: imageLoader.imageData)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 400, height: 300)) ?? NSImage(size: NSSize(width: 0, height: 0))))
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

class ImageLoaderAndCache: ObservableObject {
    
    @Published var imageData = Data()
    let imageQueue = DispatchQueue(label: "ImageQueue")

    init(imageURL: String) {
        imageQueue.async { [weak self] in
            if let url = URL(string: imageURL) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                if let data = cache?.cachedResponse(for: request)?.data {
                    DispatchQueue.main.async {
                        self?.imageData = data
                    }
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
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

//
//  Messages.swift
//  Accord
//
//  Created by evelyn on 2021-03-07.
//

import Foundation
import SwiftUI

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
        Image(nsImage: (NSImage(data: self.imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0))))
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
        Image(nsImage: (NSImage(data: self.imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0))))
              .resizable()
              .scaledToFit()
              .onDisappear {
                  self.imageLoader.imageData = Data()
              }
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


func getImage(url: String) -> Data {
    var ret: Data = Data()
    net.requestData(url: url, token: nil, json: false, type: .GET, bodyObject: [:]) { success, data in
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

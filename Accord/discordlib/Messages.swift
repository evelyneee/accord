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

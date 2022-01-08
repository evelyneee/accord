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

let cachesURL: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
let diskCacheURL = cachesURL.appendingPathComponent("DownloadCache")
let cache = URLCache(memoryCapacity: 1_000_000_000, diskCapacity: 1_000_000_000, directory: diskCacheURL)

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
              .frame(idealWidth: imageLoader.image.size.width, idealHeight: imageLoader.image.size.height)
              .scaledToFit()
              .onDisappear(perform: {
                  imageLoader.cancellable?.cancel()
              })
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

final class ImageLoaderAndCache: ObservableObject {

    @Published var image: NSImage = NSImage()
    var cancellable: AnyCancellable?
    private var url: URL?
    private var size: CGSize?

    init(imageURL: String, size: CGSize? = nil) {
        self.url = URL(string: imageURL)
        self.size = size
        self.load()
    }

    func load() {
        imageQueue.async { [weak self] in
            if self?.size?.width == 350 { print("loading attachment") }
            self?.cancellable = RequestPublisher.image(url: self?.url, to: self?.size)
                .replaceError(with: NSImage())
                .replaceNil(with: NSImage())
                .sink { img in DispatchQueue.main.async { self?.image = img } }
        }
    }
}

//
//  Images.swift
//  Accord
//
//  Created by evelyn on 2021-06-14.
//

import AppKit
import Combine
import Foundation
import SwiftUI

let cachesURL: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
let diskCacheURL = cachesURL.appendingPathComponent("DownloadCache")
let cache = URLCache(memoryCapacity: 0, diskCapacity: 1_000_000_000, directory: diskCacheURL)

struct Attachment: View, Equatable {
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        lhs.url == rhs.url
    }

    @StateObject private var imageLoader: ImageLoaderAndCache
    var url: String

    init(_ url: String, size: CGSize? = nil) {
        self.url = url
        _imageLoader = StateObject(wrappedValue: ImageLoaderAndCache(imageURL: url, size: size))
    }

    var body: some View {
        HStack {
            Image(nsImage: imageLoader.image)
                .resizable()
                .frame(idealWidth: imageLoader.image.size.width, idealHeight: imageLoader.image.size.height)
                .scaledToFit()
        }
        .onAppear {
            imageLoader.load()
        }
    }
}

struct HoveredAttachment: View, Equatable {
    static func == (_: HoveredAttachment, _: HoveredAttachment) -> Bool {
        true
    }

    @StateObject var imageLoader: ImageLoaderAndCache
    @State var hovering = false

    init(_ url: String) {
        _imageLoader = StateObject.init(wrappedValue: ImageLoaderAndCache(imageURL: url))
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
    @Published var image: NSImage = .init()
    private var url: URL?
    private var size: CGSize?

    init(imageURL: String, size: CGSize? = nil) {
        url = URL(string: imageURL)
        self.size = size
    }

    func load() {
        if self.size?.width == 350 { print("loading attachment") }
        RequestPublisher.image(url: self.url, to: self.size)
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .replaceError(with: NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "No connection") ?? NSImage())
            .receive(on: RunLoop.main)
            .assign(to: &$image)
    }
}

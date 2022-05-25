//
//  AttachmentView.swift
//  Accord
//
//  Created by evelyn on 2021-07-01
//

import AVKit
import Combine
import SwiftUI

func frameSize(width: CGFloat, height: CGFloat, originalWidth: Int?, originalHeight: Int?) -> (CGFloat, CGFloat) {
    guard let widthInt = originalWidth,
          let heighthInt = originalHeight else { return (width, height) }
    let originalWidth = CGFloat(widthInt)
    let originalHeight = CGFloat(heighthInt)
    let max: CGFloat = max(width, height)
    if originalWidth > originalHeight {
        return (max, originalHeight / originalWidth * max)
    } else {
        return (originalWidth / originalHeight * max, max)
    }
}

public extension View {
    func maxFrame(width: CGFloat, height: CGFloat, originalWidth: Int?, originalHeight: Int?) -> some View {
        let (width, height) = frameSize(width: width, height: height, originalWidth: originalWidth, originalHeight: originalHeight)
        return frame(width: width, height: height)
    }
}

struct AttachmentView: View {
    var media: [AttachedFiles]
    var body: some View {
        ForEach(media, id: \.url) { obj in
            if obj.content_type?.contains("image/") == true && obj.content_type?.contains("gif") == false {
                Attachment(obj.url, size: CGSize(width: 500, height: 500)).equatable()
                    .cornerRadius(5)
                    .maxFrame(width: 350, height: 350, originalWidth: obj.width, originalHeight: obj.height)
                    .accessibility(label: Text(obj.description ?? "Image"))
            } else if obj.content_type?.contains("gif") == true {
                GifView(obj.url)
                    .cornerRadius(5)
                    .maxFrame(width: 350, height: 350, originalWidth: obj.width, originalHeight: obj.height)
                    .accessibility(label: Text(obj.description ?? "Image"))
            } else if obj.content_type?.prefix(6).stringLiteral == "video/", let url = URL(string: obj.proxy_url) {
                VideoPlayer(player: AVPlayer(url: url))
                    .cornerRadius(5)
                    .maxFrame(width: 350, height: 350, originalWidth: obj.width, originalHeight: obj.height)
            } else {
                FileAttachmentView(file: obj)
            }
        }
    }
}

func attachmentWindows(player: AVPlayer? = nil, url: String? = nil, name: String, width: Int? = nil, height: Int? = nil) {
    var windowRef: NSWindow
    windowRef = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: CGFloat(width ?? 0), height: CGFloat(height ?? 0)),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
        backing: .buffered, defer: false
    )
    if let player = player {
        windowRef.contentView = NSHostingView(rootView: VideoPlayer(player: player).frame(idealWidth: CGFloat(width ?? 0), idealHeight: CGFloat(height ?? 0)).padding(.horizontal, 45).cornerRadius(5))
    } else if let url = url {
        windowRef.contentView = NSHostingView(rootView: Attachment(url).frame(idealWidth: CGFloat(width ?? 0), idealHeight: CGFloat(height ?? 0)).cornerRadius(5))
    }
    windowRef.minSize = NSSize(width: CGFloat(width ?? 0), height: CGFloat(height ?? 0))
    windowRef.title = name
    windowRef.isReleasedWhenClosed = false
    windowRef.makeKeyAndOrderFront(nil)
}

struct VideoPlayerController: NSViewRepresentable {
    init(url: URL) {
        player = AVPlayer(url: url)
    }

    var player: AVPlayer?
    func makeNSView(context _: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        return playerView
    }

    func updateNSView(_: AVPlayerView, context _: Context) {}
}

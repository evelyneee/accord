//
//  AttachmentView.swift
//  Accord
//
//  Created by evelyn on 2021-07-01
//

import AVKit
import Combine
import SwiftUI

struct AttachmentView: View {
    var media: [AttachedFiles]
    var body: some View {
        ForEach(media, id: \.url) { obj in
            HStack(alignment: .top) {
                VStack { [unowned obj] in
                    if obj.content_type?.prefix(6).stringLiteral == "image/" {
                        Attachment(obj.url, size: CGSize(width: 350, height: 350)).equatable()
                            .cornerRadius(5)
                            .frame(maxWidth: 350, maxHeight: 350)
                    } else if obj.content_type?.prefix(6).stringLiteral == "video/", let url = URL(string: obj.url) {
                        VideoPlayer(player: AVPlayer.init(url: url))
                            .cornerRadius(5)
                            .frame(minWidth: 300, minHeight: 300)
                            .onDisappear {
                                print("goodbye")
                            }
                    }
                }
                Button(action: { [weak obj] in
                    if obj?.content_type?.prefix(6).stringLiteral == "video/" {
                        attachmentWindows(
                            player: AVPlayer(url: URL(string: obj?.url ?? "")!),
                            url: nil,
                            name: (obj?.filename)!,
                            width: (obj?.width)!,
                            height: (obj?.height)!
                        )
                    } else if obj?.content_type?.prefix(6).stringLiteral == "image/" {
                        attachmentWindows(
                            player: nil,
                            url: (obj?.url)!,
                            name: (obj?.filename)!,
                            width: (obj?.width)!,
                            height: (obj?.height)!
                        )
                    } else {
                        NSWorkspace.shared.open(URL(string: obj?.url ?? "")!)
                    }
                }) {
                    Image(systemName: "arrow.up.forward.circle")
                }
                .buttonStyle(BorderlessButtonStyle())
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

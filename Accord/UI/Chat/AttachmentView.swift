//
//  AttachmentView.swift
//  Accord
//
//  Created by evelyn on 2021-07-01.
//

import SwiftUI
import AVKit
import Combine

struct AttachmentView: View, Equatable {
    static func == (lhs: AttachmentView, rhs: AttachmentView) -> Bool {
        return lhs.media.map { $0.url } == rhs.media.map { $0.url }
    }
    var media: [AttachedFiles]
    init(_ media: [AttachedFiles]) {
        self.media = media
    }
    var body: some View {
        ForEach(media, id: \.url) { obj in
            HStack(alignment: .top) {
                VStack {
                    if obj.content_type?.prefix(6).stringLiteral == "image/" {
                        Attachment(obj.url, size: CGSize(width: obj.width ?? 1000, height: obj.height ?? 1000)).equatable()
                            .cornerRadius(5)
                    } else if obj.content_type?.prefix(6).stringLiteral == "video/" {
                        VideoPlayer(player: AVPlayer(url: URL(string: obj.url)!))
                            .cornerRadius(5)
                    }
                }
                .frame(width: Double(obj.width ?? 1000) * 0.4, height: Double(obj.height ?? 1000) * 0.4)
                Button(action: { [weak obj] in
                    if obj?.content_type?.prefix(6).stringLiteral == "video/" {
                        attachmentWindows(player: AVPlayer(url: URL(string: obj?.url ?? "")!), url: nil, name: (obj?.filename)!, width: (obj?.width)!, height: (obj?.height)!)
                    } else {
                        attachmentWindows(player: nil, url: (obj?.url)!, name: (obj?.filename)!, width: (obj?.width)!, height: (obj?.height)!)
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
        backing: .buffered, defer: false)
    if player != nil {
         windowRef.contentView = NSHostingView(rootView: VideoPlayer(player: player!).frame(idealWidth: CGFloat(width ?? 0), idealHeight: CGFloat(height ?? 0)).padding(.horizontal, 45).cornerRadius(5))
    }
    if url != nil {
        windowRef.contentView = NSHostingView(rootView: Attachment(url ?? "").frame(idealWidth: CGFloat(width ?? 0), idealHeight: CGFloat(height ?? 0)).cornerRadius(5))
    }
    windowRef.minSize = NSSize(width: CGFloat(width ?? 0), height: CGFloat(height ?? 0))
    windowRef.isReleasedWhenClosed = false
    windowRef.title = name
    windowRef.makeKeyAndOrderFront(nil)
}


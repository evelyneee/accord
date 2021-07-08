//
//  AttachmentView.swift
//  Accord
//
//  Created by evelyn on 2021-07-01.
//

import SwiftUI
import AVKit
import Combine

struct AttachmentView: View {
    @Binding var media: [AttachedFiles?]
    var body: some View {
        VStack {
            ForEach(0..<media.count, id: \.self) { index in
                VStack {
                    if String((media[index]?.content_type ?? "").prefix(6)) == "image/" {
                        HStack(alignment: .top) {
                            Attachment(media[index]!.url)
                                .cornerRadius(5)
                        }
                    } else if String((media[index]?.content_type ?? "").prefix(6)) == "video/" {
                        HStack(alignment: .top) {
                            VideoPlayer(player: AVPlayer(url: URL(string: (media[index]?.url)!)!))
                                .frame(width: 400, height: 300)
                                .padding(.horizontal, 45)
                                .cornerRadius(5)

                        }
                    }
                }

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


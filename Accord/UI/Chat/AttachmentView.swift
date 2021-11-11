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
        return true
    }
    @Binding var media: [AttachedFiles?]
    @State var currentImage: NSImage = NSImage()
    @State var animatedImages: [NSImage]? = []
    @State var counterValue: Int = 0
    @State var duration: Double = 0
    @State var setinterval: Double = 1
    @State var value: Int = 0
    @State var timer: Timer?
    let attachmentQueue = DispatchQueue(label: "AttachmentQueue", attributes: .concurrent)
    var body: some View {
        VStack {
            ForEach(0..<media.count, id: \.self) { index in
                HStack(alignment: .top) {
                    VStack {
                        if String((media[index]?.content_type ?? "").prefix(6)) == "image/" {
                            HStack(alignment: .top) {
                                if (media[index]?.content_type ?? "") == "image/gif" {
                                    if animatedImages?.count != 0 {
                                        Image(nsImage: animatedImages?[value % (animatedImages?.count ?? 1)] ?? NSImage()).resizable()
                                            .scaledToFit()
                                            .frame(width: 400, height: 300)
                                    } else {
                                        Text("Loading...")
                                            .onAppear {
                                                attachmentQueue.async {
                                                    currentImage = NSImage()
                                                    Request().image(url: URL(string: media[index]!.url), to: nil) { image in
                                                        guard let gif = image as? Gif else { return }
                                                        animatedImages = gif.animatedImages
                                                        duration = Double(CFTimeInterval(gif.calculatedDuration ?? 0))
                                                        setinterval = Double(duration / Double(animatedImages?.count ?? 1))
                                                        print(Double(duration / Double(animatedImages?.count ?? 1)))
                                                        self.timer = Timer.scheduledTimer(withTimeInterval: Double(duration / Double(animatedImages?.count ?? 1)), repeats: true) { _ in
                                                            if self.setinterval != 0 {
                                                                print(value)
                                                                (self.value) += 1 % animatedImages!.count
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                    }

                                } else {
                                    StockAttachment(media[index]!.url).equatable()
                                        .cornerRadius(5)
                                }
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
                    if let item = media[index] {
                        Button(action: { [weak item] in
                            if String((item?.content_type ?? "").prefix(6)) == "video/" {
                                attachmentWindows(player: AVPlayer(url: URL(string: (item?.url)!)!), url: nil, name: (item?.filename)!, width: (item?.width)!, height: (item?.height)!)
                            } else {
                                attachmentWindows(player: nil, url: (item?.url)!, name: (item?.filename)!, width: (item?.width)!, height: (item?.height)!)
                            }
                        }) {
                            Image(systemName: "arrow.up.forward.circle")
                        }
                        .buttonStyle(BorderlessButtonStyle())
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


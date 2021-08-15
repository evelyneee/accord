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
    @State var currentImage: NSImage = NSImage()
    @State var animatedImages: [NSImage]? = []
    @State var counterValue: Int = 0
    @State var duration: Double = 0
    @State var setinterval: Double = 1
    @State var value: Int = 0
    @State var timer: Timer?
    let attachmentQueue = DispatchQueue(label: "AttachmentQueue")
    var body: some View {
        VStack {
            ForEach(0..<media.count, id: \.self) { index in
                VStack {
                    if String((media[index]?.content_type ?? "").prefix(6)) == "image/" {
                        HStack(alignment: .top) {
                            if (media[index]?.content_type ?? "") == "image/gif" {
                                if animatedImages?.count != 0 {
                                    Image(nsImage: animatedImages?[value % (animatedImages?.count ?? 1)] ?? NSImage()).resizable()
                                        .scaledToFit()
                                        .frame(width: 400, height: 300)

                                } else {
                                    Text("...")
                                        .onAppear {
                                            attachmentQueue.async {
                                                currentImage = NSImage()
                                                NetworkHandling.shared?.requestData(url: media[index]!.url, token: nil, json: false, type: .GET, bodyObject: [:]) { success, data in
                                                    if success,
                                                          let data = data,
                                                       let amyGif = Gif(data: data) {
                                                        DispatchQueue.main.async {
                                                            animatedImages = amyGif.animatedImages
                                                            duration = Double(CFTimeInterval(amyGif.calculatedDuration ?? 0))
                                                            setinterval = Double(duration / Double(animatedImages?.count ?? 1))
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
                                        }
                                }

                            } else {
                                Attachment(media[index]!.url).equatable()
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

            }
            .onChange(of: media) { newValue in
                media = newValue
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


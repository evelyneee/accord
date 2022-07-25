//
//  SwiftUI++.swift
//  Accord
//
//  Created by evelyn on 2022-01-03.
//

import AVKit
import Combine
import Foundation
import SwiftUI
import WebKit

extension Button {
    init(action: @escaping () throws -> Void, catch: @escaping (_ error: Error?) -> Void, label: @escaping () -> Label) {
        self.init(action: {
            do {
                try action()
            } catch {
                `catch`(error)
            }
        }, label: label)
    }
}

struct RoundedCorners: Shape {
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height

        // Make sure we do not exceed the size of the rectangle
        let tr = min(min(tr, h / 2), w / 2)
        let tl = min(min(tl, h / 2), w / 2)
        let bl = min(min(bl, h / 2), w / 2)
        let br = min(min(br, h / 2), w / 2)

        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr,
                    startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)

        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br,
                    startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)

        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl,
                    startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                    startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()

        return path
    }
}

struct FastButton<Content: View>: View {
    var action: () -> Void
    var label: () -> Content
    var body: some View {
        label()
            .onTapGesture(perform: action)
    }
}

struct WebVideoPlayer: NSViewRepresentable {
    init(url: URL) {
        self.url = url
    }

    let url: URL

    func makeNSView(context _: Context) -> WKWebView {
        var webView = WKWebView()
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        let html = "<video playsinline controls width=\"100%\" src=\"\(url.absoluteString)\"> </video>"
        webView.loadHTMLString(html, baseURL: url)
        print(html, webView)
        return webView
    }

    func updateNSView(_: WKWebView, context _: Context) {}
}

extension GridItem {
    static func multiple(count: Int, size: Self.Size = .flexible(), spacing: CGFloat? = nil, alignment: SwiftUI.Alignment? = nil) -> [GridItem] {
        Array(repeating: GridItem(size, spacing: spacing, alignment: alignment), count: count)
    }
}

struct SafeVideoPlayer: View {
    @StateObject var model: VideoPlayerModel

    final class VideoPlayerModel: ObservableObject {
        init(url: URL) {
            self.url = url
        }

        func loadVideo() {
            if player == nil {
                let playerItem = AVPlayerItem(url: url)
                player = AVPlayer(playerItem: playerItem)
            }
        }

        private(set) var url: URL
        @Published var player: AVPlayer?
    }

    init?(url: String) {
        guard let url = URL(string: url) else { return nil }
        _model = StateObject(wrappedValue: VideoPlayerModel(url: url))
    }

    var body: some View {
        VideoPlayer(player: model.player)
            .onAppear {
                print("loading")
                model.loadVideo()
            }
            .onDisappear { [weak model] in
                print("bye")
                model?.player?.replaceCurrentItem(with: nil)
            }
    }
}

extension Font {
    static var chatTextFont = Font.system(size: 14.5, design: .rounded)
}

extension View {
    func imageRepresentation(_ completion: @escaping (NSImage?) -> Void) {
        let view = NoInsetHostingView(rootView: self)
        view.setFrameSize(view.fittingSize)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(view.bitmapImage())
        }
    }
}

class NoInsetHostingView<V>: NSHostingView<V> where V: View {
    override var safeAreaInsets: NSEdgeInsets {
        .init()
    }
}

public extension NSView {
    func bitmapImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        guard let cgImage = rep.cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}

struct NotificationBadge: ViewModifier {
    @Binding var count: Int?
    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content
            if let count = count, count != 0 {
                ZStack {
                    Circle()
                        .foregroundColor(.red)
                        .opacity(0.9)
                        .shadow(radius: 0.25)
                    Text(String(count))
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .frame(width: 17.5, height: 17.5)
                .padding([.bottom, .trailing], -1)
            }
        }
    }
}

extension View {
    func redBadge(_ count: Binding<Int?>) -> some View {
        modifier(NotificationBadge(count: count))
    }

    @ViewBuilder
    func conditionalClipShape<S: Shape, U: Shape>(_ condition: Bool, _ shape1: S, _ shape2: U) -> some View {
        if condition {
            clipShape(shape1)
        } else {
            clipShape(shape2)
        }
    }
}

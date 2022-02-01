//
//  GifView.swift
//  Accord
//
//  Created by evelyn on 2021-12-24.
//

import AppKit
import Combine
import Foundation
import SwiftUI

struct GifView: View {
    var url: String
    @State var currentImage: NSImage = .init()
    @State var animatedImages: [NSImage] = []
    @State var counterValue: Int = 0
    @State var duration: Double = 0
    @State var value: Int = 0
    @State var timer: Cancellable?
    @State private var can: AnyCancellable?
    var body: some View {
        ZStack {
            if animatedImages.isEmpty {
                Image(nsImage: NSImage())
            } else {
                Image(nsImage: animatedImages[value]).resizable()
                    .scaledToFit()
            }
        }
        .onAppear { print("hi"); prep() }
        .onDisappear { timer?.cancel(); timer = nil }
    }

    func prep() {
        gifQueue.async {
            can = URLSession.shared.dataTaskPublisher(for: URL(string: url)!)
                .map(\.data)
                .replaceError(with: Data())
                .sink { data in
                    let gif = Gif(data: data)
                    animatedImages = gif?.animatedImages ?? []
                    duration = Double(CFTimeInterval(gif?.calculatedDuration ?? 0))
                    DispatchQueue.main.async {
                        self.timer = Timer.publish(
                            every: Double(duration / Double(animatedImages.count)),
                            tolerance: nil,
                            on: .main,
                            in: .default
                        )
                        .autoconnect()
                        .sink { _ in
                            if value + 1 == animatedImages.count {
                                self.value = 0
                                return
                            }
                            (self.value) += 1 % (animatedImages.count)
                        }
                    }
                }
        }
    }
}

struct HoverGifView: View {
    var url: String
    @State var animatedImages: [NSImage] = []
    @State var counterValue: Int = 0
    @State var duration: Double = 0
    @State var value: Int = 0
    @State var timer: Cancellable?
    @State private var can: AnyCancellable?
    @State var animated: Bool = false
    var body: some View {
        HStack {
            if !animatedImages.isEmpty {
                Image(nsImage: animated ? animatedImages[value] : animatedImages[0])
                    .resizable()
                    .scaledToFit()
                    .onHover { _ in animated.toggle() }
                    .onDisappear { print(url, "baibai"); timer?.cancel(); timer = nil; animatedImages.removeAll() }
            } else {
                Text("...")
                    .onAppear {
                        guard animatedImages.isEmpty else { print("uh fuk"); return }
                        print("instance created", url)
                        prep()
                    }
            }
        }
    }

    func prep() {
        gifQueue.async {
            guard let url = URL(string: url) else { return }
            can = URLSession.shared.dataTaskPublisher(for: url)
                .map(\.data)
                .replaceError(with: Data())
                .sink { data in
                    let gif = Gif(data: data)
                    animatedImages = gif?.animatedImages ?? []
                    duration = Double(CFTimeInterval(gif?.calculatedDuration ?? 0))
                    DispatchQueue.main.async {
                        self.timer = Timer.publish(
                            every: Double(duration / Double(animatedImages.count)),
                            tolerance: nil,
                            on: .main,
                            in: .default
                        )
                        .autoconnect()
                        .sink { _ in
                            if value + 1 == animatedImages.count {
                                self.value = 0
                                return
                            }
                            (self.value) += 1 % (animatedImages.count)
                        }
                    }
                }
        }
    }
}

//
//  GifView.swift
//  Accord
//
//  Created by evelyn on 2021-12-24.
//

import Foundation
import SwiftUI
import AppKit
import Combine

struct GifView: View {
    var url: String
    @State var currentImage: NSImage = NSImage()
    @State var animatedImages: [NSImage] = []
    @State var counterValue: Int = 0
    @State var duration: Double = 0
    @State var value: Int = 0
    @State var timer: Timer?
    @State private var can: AnyCancellable? = nil
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
        .onDisappear { timer?.invalidate() }
    }
    func prep() {
        gifQueue.async {
            can = URLSession.shared.dataTaskPublisher(for: URL(string: url)!)
                .map { $0.data }
                .replaceError(with: Data())
                .sink(receiveValue: { data in
                    let gif = Gif(data: data)
                    animatedImages = gif?.animatedImages ?? []
                    duration = Double(CFTimeInterval(gif?.calculatedDuration ?? 0))
                    DispatchQueue.main.async {
                        self.timer = Timer.scheduledTimer(withTimeInterval: Double(duration / Double(animatedImages.count)), repeats: true) { _ in
                            if value + 1 == animatedImages.count {
                                self.value = 0
                                return
                            }
                            (self.value) += 1 % (animatedImages.count)
                        }
                    }
                })
        }
    }
}

struct HoverGifView: View {
    var url: String
    @State var animatedImages: [NSImage] = []
    @State var counterValue: Int = 0
    @State var duration: Double = 0
    @State var value: Int = 0
    @State var timer: Timer? = nil
    @State private var can: AnyCancellable? = nil
    @State var animated: Bool = false
    var body: some View {
        ZStack {
            if animatedImages.isEmpty {
                Image(nsImage: NSImage())
            } else {
                Image(nsImage: animated ? animatedImages[value] : animatedImages[0] )
                    .resizable()
                    .scaledToFit()
                    .onDisappear { [weak timer] in
                        print("adios")
                        timer?.invalidate(); timer = nil
                    }
            }
        }
        .onHover { _ in animated.toggle() }
        .onAppear { prep() }
    }
    func prep() {
        print("prep")
        gifQueue.async {
            can = URLSession.shared.dataTaskPublisher(for: URL(string: url)!)
                .map { $0.data }
                .replaceError(with: Data())
                .sink(receiveValue: { data in
                    guard let gif = Gif(data: data) else { return }
                    animatedImages = gif.animatedImages ?? []
                    duration = Double(CFTimeInterval(gif.calculatedDuration ?? 0))
                    DispatchQueue.main.async {
                        guard timer == nil else { return }
                        print("timer init \(url)")
                        self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.duration / Double(self.animatedImages.count)), repeats: true) { _ in
                            self.fireAction()
                        }
                    }
                })
        }
    }
    func fireAction() {
        print("fired")
        if value + 1 == animatedImages.count {
            self.value = 0
            return
        }
        (self.value) += 1 % (animatedImages.count)
    }
}

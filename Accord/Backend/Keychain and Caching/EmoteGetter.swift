//
// EmoteGetter.swift
// NitrolessMac
//
// Created by e b on 12.02.21
//

import SwiftUI
import AppKit

class Counter: ObservableObject {
    var timer: Timer?
    
    @Published var value: Int = 0
    @Published var setinterval: Double = 0 {
        didSet {
            print("[Accord] set")
            timer = Timer.scheduledTimer(withTimeInterval: setinterval, repeats: true) { _ in
                if self.setinterval != 0 {
                    self.value += 1
                }
            }
        }
    }
    
    init(interval: Double) {
        timer = Timer.scheduledTimer(withTimeInterval: setinterval, repeats: true) { _ in
            if self.setinterval != 0 {
                self.value += 1
            }
        }
    }
}


struct GifView: View {
    @Binding var url: String
    @State var currentImage: NSImage = NSImage()
    @State var animatedImages: [NSImage]? = []
    @State var counterValue: Int = 0
    @State var duration: Double = 0
    @State var setinterval: Double = 1
    @State var value: Int = 0
    @State var timer: Timer?
    var body: some View {
        ZStack {
            if animatedImages?.count == 0 {
                Image(nsImage: NSImage())
            } else {
                Image(nsImage: animatedImages?[value] ?? NSImage()).resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                currentImage = NSImage()

                NetworkHandling.shared?.requestData(url: url, token: nil, json: false, type: .GET, bodyObject: [:]) { success, data in
                    if success,
                          let data = data,
                       let amyGif = Gif(data: data) {
                        DispatchQueue.main.async {
                            animatedImages = amyGif.animatedImages
                            duration = Double(CFTimeInterval(amyGif.calculatedDuration ?? 0))
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
        }
    }
}

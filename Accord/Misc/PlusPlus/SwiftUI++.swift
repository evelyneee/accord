//
//  SwiftUI++.swift
//  Accord
//
//  Created by evelyn on 2022-01-03.
//

import Foundation
import SwiftUI
import Combine

extension Button {
    init(action: @escaping () throws -> Void, catch: @escaping () -> Void, label: @escaping () -> Label) {
        self.init(action: {
            do {
                try action()
            } catch {
                `catch`()
            }
        }, label: label)
    }
}

struct AsyncView<Content: View, D: Decodable>: View {
    
    @State var cancellable: AnyCancellable? = nil
    @State var d: D? = nil
    @State var error: Error? = nil

    private var completion: (D?, Error?) -> Content
    private var headers: Headers?
    private var url: URL?
    private var queue: DispatchQueue
    
    init(_ type: D.Type, _ url: URL?, headers: Headers? = nil, on queue: DispatchQueue, content: @escaping (D?, Error?) -> Content) {
        self.url = url
        self.headers = headers
        self.completion = content
        self.queue = queue
    }
    
    func load() {
        queue.async {
            self.cancellable = RequestPublisher.fetch(D.self, url: url, headers: headers)
                .sink(receiveCompletion: { completion in
                    dump(completion)
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        self.error = error
                    }
                }, receiveValue: { d in
                    self.d = d
                })
        }
    }
    
    var body: some View {
        HStack {
            completion(d, error)
        }
        .onAppear(perform: {
            self.load()
        })
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
        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)
        
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

//
//  LoadingScreenView.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation
import SwiftUI

struct TiltAnimation: ViewModifier {
    @State var rotated: Bool = false
    @State var timer: Timer?
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotated ? 10 : -10))
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                    withAnimation(Animation.spring()) {
                        rotated.toggle()
                    }
                }
            }
    }
}

internal extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool,
                                          transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}

struct LoadingView: View {

    fileprivate static let greetings: [Text] = [
        Text("Entering girlmode"),
        Text("Stay dry"),
        Text("Gaslight. Gatekeep. Girlboss.").italic(),
        Text("Not a car"),
        Text("Ratio + Civic better"),
        Text("Send your best hints to ") + Text("evln#0001").font(Font.system(.title2, design: .monospaced)),
        Text("Never gonna give you up, never gonna use electron"),
        Text("Tell ur oomfies")
    ]

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .saturation(0.0).modifier(TiltAnimation())
                    LoadingView.greetings.randomElement()!
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(5)
                    Text("Connecting")
                        .foregroundColor(Color.secondary)
                }
                Spacer()
            }
            Spacer()
        }
    }
}

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
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotated ? 10 : -10))
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                    withAnimation(Animation.spring()) {
                        rotated.toggle()
                    }
                }
            }
    }
}

internal extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool,
                                          transform: (Self) -> Content) -> _ConditionalContent<Content, Self>
    {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}

struct LoadingView: View {
    fileprivate static let greetings: [Text] = [
        Text("Made in Canada!"),
        Text("Gaslight. Gatekeep. Girlboss.").italic(),
        Text("Send your best hints to ") + Text("evln#0001").font(Font.system(.title2, design: .monospaced)),
        Text("You can change your nickname with ") + Text("/nick").font(Font.system(.title2, design: .monospaced)),
        Text("can you find all 12 frogs?"),
        Text("according to my sources").italic(),
        Text("swift... you... why!!!"),
        Text("🤸🏻‍♀️").font(.system(size: 36)),
        Text("Make sure to join the official server!"),
        Text("Let's merge without conflicts 😳"),
        Text("Wumpus is now a feral possum"),
        Text("Accord is behind you"),
        Text("Boo 👻"),
        Text("Click [here](https://www.youtube.com/watch?v=dQw4w9WgXcQ) for a surprise"),
        Text("Check out ") + Text("/help").font(Font.system(.title2, design: .monospaced)),
    ]

    var body: some View {
        VStack {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .saturation(0.0).modifier(TiltAnimation())
            LoadingView.greetings.randomElement()!
                .fontWeight(.medium)
                .font(.title2)
                .textSelection(.enabled)
                .padding(5)
            Text("Connecting")
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .focusable(false)
    }
}

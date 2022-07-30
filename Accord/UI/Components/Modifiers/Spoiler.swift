//
//  Spoiler.swift
//  Accord
//
//  Created by evelyn on 2022-07-29.
//

import SwiftUI

struct MediaSpoiler: ViewModifier {
    @State var shown: Bool = false
    func body(content: Content) -> some View {
        Button(action: {
            withAnimation(.linear(duration: 0.1)) {
                self.shown = true
            }
        }) {
            ZStack {
                content
                    .blur(radius: shown ? 0 : 10)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                if !shown {
                    Text("SPOILER")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .font(.subheadline)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 25).fill(Color(NSColor.darkGray)))
                }
            }
        }
        .buttonStyle(.borderless)
    }
}

//
//  Popup.swift
//  Accord
//
//  Created by evelyn on 2022-06-30.
//

import SwiftUI

struct PopupOnClick<Content2: View, ButtonStyle2: PrimitiveButtonStyle>: ViewModifier {
    @State var shown: Bool = false
    var content2: () -> Content2
    var buttonStyle: ButtonStyle2
    
    @ViewBuilder
    func body(content: Content) -> some View {
        Button(action: {
            self.shown.toggle()
        }) {
            content
        }
        .buttonStyle(buttonStyle)
        .popover(isPresented: self.$shown, content: {
            self.content2()
        })
    }
}

extension View {
    func popupOnClick<Content: View, ButtonStyle2: PrimitiveButtonStyle>(buttonStyle: ButtonStyle2 = PlainButtonStyle(), content: @escaping () -> Content) -> some View {
        modifier(PopupOnClick.init(content2: content, buttonStyle: buttonStyle))
    }
}

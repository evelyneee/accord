//
//  JoinServerButton.swift
//  Accord
//
//  Created by evelyn on 2022-05-30.
//

import SwiftUI

struct JoinServerButton: View {
    @State var isShowingJoinServerSheet: Bool = false
    @State var iconHovered: Bool = false

    private var iconView: some View {
        Image(systemName: "plus")
            .imageScale(.large)
            .frame(width: 50, height: 50)
            .background(self.isShowingJoinServerSheet ? Color.accentColor.opacity(0.5) : Color(NSColor.secondaryLabelColor).opacity(0.2))
            .cornerRadius(iconHovered || self.isShowingJoinServerSheet ? 13.5 : 23.5)
    }

    var body: some View {
        Button(action: {
            isShowingJoinServerSheet.toggle()
        }, label: {
            iconView
                .foregroundColor(self.isShowingJoinServerSheet ? .white : nil)
                .onHover(perform: { h in withAnimation(Animation.linear(duration: 0.1)) { self.iconHovered = h } })
        })
        .buttonStyle(.borderless)
        .sheet(isPresented: $isShowingJoinServerSheet) {
            JoinServerSheetView(isPresented: $isShowingJoinServerSheet)
                .frame(width: 300, height: 120)
                .padding()
        }
    }
}

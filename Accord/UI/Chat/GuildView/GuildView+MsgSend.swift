//
//  GuildView+MsgSend.swift
//  GuildView+MsgSend
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

extension GuildView {
    var sendingView: some View {
        return HStack(alignment: .top) {
            Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                .scaledToFit()
                .frame(width: 33, height: 33)
                .padding(.horizontal, 5)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(username)
                    .fontWeight(.semibold)
                if let temp = chatTextFieldContents {
                    Text(temp)
                }
            }
            Spacer()
        }
        .rotationEffect(.radians(.pi))
        .scaleEffect(x: -1, y: 1, anchor: .center)
        .opacity(0.75)
    }
}

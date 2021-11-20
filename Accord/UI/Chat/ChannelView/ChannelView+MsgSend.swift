//
//  ChannelView+MsgSend.swift
//  ChannelView+MsgSend
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

extension ChannelView {
    var sendingView: some View {
        return HStack(alignment: .top) {
            if viewModel.messages.first?.author?.id != user_id {
                Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                    .scaledToFit()
                    .frame(width: 33, height: 33)
                    .clipShape(Circle())
            }
//            VStack(alignment: .leading) {
//                if viewModel.messages.first?.author?.id != user_id {
//                    Text(username)
//                        .fontWeight(.semibold)
//                    if let temp = chatTextFieldContents {
//                        Text(temp)
//                    }
//                } else {
//                    if let temp = chatTextFieldContents {
//                        Text(temp)
//                            .padding(.leading, 41)
//                    }
//                }
//
//            }
            Spacer()
            Button(action: {
            }) {
                Image(systemName: "arrow.left.circle.fill")
            }
            .buttonStyle(BorderlessButtonStyle())
            Button(action: {
            }) {
                Image(systemName: "arrowshape.turn.up.backward.fill")
            }
            .buttonStyle(BorderlessButtonStyle())
            Button(action: {
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .rotationEffect(.radians(.pi))
        .scaleEffect(x: -1, y: 1, anchor: .center)
        .opacity(0.75)
    }
}

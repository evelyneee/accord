//
//  ChannelView+TextField.swift
//  ChannelView+TextField
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

extension ChannelView {
    var blurredTextField: some View {
        VStack(alignment: .leading, spacing: 0) {
            if replyingTo != nil || !typing.isEmpty {
                HStack {
                    if let replied = replyingTo {
                        Text("replying to \(replied.author?.username ?? "")")
                            .lineLimit(0)
                            .font(.subheadline)
                    }
                    if !(typing.isEmpty) {
                        Text("\(typing.joined(separator: ", ")) \(typing.count == 1 ? "is" : "are") typing")
                            .lineLimit(0)
                            .font(.subheadline)
                    }
                    if replyingTo != nil {
                        Spacer()
                        Button(action: {
                            mentionUser.toggle()
                        }, label: {
                            Image(systemName: mentionUser ? "bell.fill" : "bell")
                                .foregroundColor(mentionUser ? .accentColor : .secondary)
                                .accessibility(label: Text(mentionUser ? "Mention users" : "Don't mention users"))
                        })
                        .buttonStyle(BorderlessButtonStyle())
                        Button(action: {
                            replyingTo = nil
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                        })
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                Divider()
            }
            ChatControls(
                guildID: Binding.constant(guildID),
                channelID: Binding.constant(channelID),
                chatText: Binding.constant("Message #\(channelName)"),
                replyingTo: $replyingTo,
                mentionUser: $mentionUser,
                permissions: $viewModel.permissions,
                fileUpload: $fileUpload,
                fileUploadURL: $fileUploadURL
            )
            .padding(13)
        }
        .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
        .clipShape(RoundedCorners(tl: replyingTo != nil || !typing.isEmpty ? 7 : 12, tr: replyingTo != nil || !typing.isEmpty ? 7 : 12, bl: 12, br: 12))
        .padding(12)
        .padding(.bottom, 2)
    }
}

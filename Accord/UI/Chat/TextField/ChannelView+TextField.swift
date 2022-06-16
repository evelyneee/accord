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
        VStack(alignment: .leading, spacing: 0) { [unowned viewModel] in
            if replyingTo != nil || !viewModel.typing.isEmpty {
                HStack {
                    if let replied = replyingTo {
                        Text("replying to \(replied.author?.username ?? "")")
                            .lineLimit(0)
                            .font(.subheadline)
                    }
                    if !(viewModel.typing.isEmpty) {
                        Text("\(viewModel.typing.joined(separator: ", ")) \(viewModel.typing.count == 1 ? "is" : "are") typing")
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
                guildID: viewModel.guildID,
                channelID: viewModel.channelID,
                chatText: "Message #\(channelName)",
                replyingTo: $replyingTo,
                mentionUser: $mentionUser,
                permissions: viewModel.permissions,
                fileUploads: self.$fileUploads
            )
            .padding(13)
        }
        .background(Color(NSColor.alternatingContentBackgroundColors[1]))
        .clipShape(RoundedCorners(tl: replyingTo != nil || !viewModel.typing.isEmpty ? 6 : 9, tr: replyingTo != nil || !viewModel.typing.isEmpty ? 6 : 9, bl: 9, br: 9))
        .padding([.horizontal, .bottom], 12)
        .padding(.bottom, 2)
        .background(colorScheme == .dark ? Color.darkListBackground : Color(NSColor.controlBackgroundColor))
    }
}

extension Color {
    static var darkListBackground: Color? {
        if #available(macOS 13.0, *) {
            return Color(NSColor.alternatingContentBackgroundColors[0])
        }
        return nil
    }
}

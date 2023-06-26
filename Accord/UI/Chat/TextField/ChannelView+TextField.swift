//
//  ChannelView+TextField.swift
//  ChannelView+TextField
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

struct SquishyButtonTextStyle: ButtonStyle {
    @State var hover = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(2)
            .padding(.horizontal, 3)
            .background(self.hover ? Color.secondary.opacity((configuration.isPressed ? 0.5 : 0.25)) : nil)
            .cornerRadius(5)
            .foregroundColor(configuration.isPressed ? .secondary : .white)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.linear(duration: 0.05), value: configuration.isPressed)
            .onHover(perform: { h in withAnimation(.linear(duration: 0.1)) { self.hover = h } })
    }
}

extension ChannelView {
    var blurredTextField: some View {
        GroupBox {
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
                    .padding(.bottom, 5)
                    .padding(.horizontal, 5)
                    Divider().padding(.bottom, 3)
                } else if let error = viewModel.error {
                    HStack {
                        Group {
                            Text("Error loading: ").bold()
                            +
                            Text(String(error.code)).bold()
                            +
                            Text(" " + (error.message ?? "Unknown error")).bold()
                        }
                        .lineLimit(0)
                        .font(.subheadline)
                        Spacer()
                        Button(action: { [weak viewModel] in
                            if error.code == 502 || error.code == -1009 {
                                concurrentQueue.async {
                                    wss?.reset()
                                }
                            } else {
                                self.viewModel.error = nil
                                viewModel?.cancellable.forEach { $0.cancel() }
                                viewModel?.cancellable.removeAll()
                                viewModel?.connect()
                                if viewModel?.guildID == "@me" {
                                    try? wss.subscribeToDM(self.channel.id)
                                } else {
                                    try? wss.subscribe(to: self.channel.guild_id ?? "@me")
                                }
                                viewModel?.getMessages(channelID: self.channel.id, guildID: self.channel.guild_id ?? "@me")
                            }
                        }) {
                            if error.code == 502 || error.code == -1009 {
                                Text("Reconnect")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            } else {
                                Text("Try again")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(SquishyButtonTextStyle())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(3)
                    .padding(.bottom, 3)
                }
                ChatControls(
                    guildID: viewModel.guildID,
                    channelID: viewModel.channelID,
                    chatText: "Message #\(channelName)",
                    permissions: viewModel.permissions,
                    replyingTo: $replyingTo,
                    mentionUser: $mentionUser,
                    fileUploads: self.$fileUploads
                )
                .padding(10)
            }
        }
        .groupBoxStyle(TextFieldStyle())
//        .background(Color(NSColor.alternatingContentBackgroundColors[1]))
//        .clipShape(RoundedCorners(tl: replyingTo != nil || !viewModel.typing.isEmpty ? 6 : 9, tr: replyingTo != nil || !viewModel.typing.isEmpty ? 6 : 9, bl: 9, br: 9))
        .padding([.horizontal, .bottom], 12)
        .background(colorScheme == .dark ? Color.darkListBackground : Color(NSColor.controlBackgroundColor))
    }
}

extension View {
    func gradientBackground(_ color: Color?) -> some View {
        if #available(macOS 13.0, *) {
            return self.background(color?.gradient ?? Color.primary.gradient)
        } else {
            return self.background(color)
        }
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

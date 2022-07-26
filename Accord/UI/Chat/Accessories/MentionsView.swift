//
//  MentionsView.swift
//  Accord
//
//  Created by evelyn on 2021-12-21.
//

import Combine
import Foundation
import SwiftUI

struct MentionsView: View {
    @State var mentions: [Message] = []
    @State var bag = Set<AnyCancellable>()
    @Binding var replyingTo: Message?

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        List($mentions, id: \.id) { $message in
            ZStack(alignment: .topTrailing) {
                MessageCellView(
                    message: $message,
                    nick: nil,
                    replyNick: nil,
                    pronouns: nil,
                    avatar: nil,
                    permissions: .constant(.init()),
                    role: Binding.constant(nil),
                    replyRole: Binding.constant(nil),
                    replyingTo: $replyingTo
                )
                Button("Jump") {
                    MentionSender.shared.select(channel: Channel(id: message.channelID, type: .normal, guild_id: message.reference?.guildID, position: nil, parent_id: nil))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                        ChannelView.scrollTo.send((message.channelID, message.id))
                    })
                }
                .buttonStyle(.borderless)
            }
        }
        .onAppear(perform: {
            messageFetchQueue.async {
                RequestPublisher.fetch([Message].self, url: URL(string: "\(rootURL)/users/@me/mentions?limit=50&roles=true&everyone=true"), headers: Headers(
                    token: Globals.token,
                    type: .GET,
                    discordHeaders: true,
                    referer: "https://discord.com/channels/@me"
                ))
                .replaceError(with: [])
                .sink { messages in
                    DispatchQueue.main.async {
                        self.mentions = messages
                    }
                }
                .store(in: &bag)
            }
        })
        .onExitCommand {
            print("bye!")
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

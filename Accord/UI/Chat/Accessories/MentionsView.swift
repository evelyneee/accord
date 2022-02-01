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
    var body: some View {
        List($mentions, id: \.id) { $message in
            MessageCellView(
                message: message,
                nick: nil,
                replyNick: nil,
                pronouns: nil,
                avatar: nil,
                guildID: nil,
                role: Binding.constant(nil),
                replyRole: Binding.constant(nil),
                replyingTo: $replyingTo
            )
        }
        .onAppear(perform: {
            messageFetchQueue.async {
                RequestPublisher.fetch([Message].self, url: URL(string: "\(rootURL)/users/@me/mentions?limit=50&roles=true&everyone=true"), headers: Headers(
                    userAgent: discordUserAgent,
                    token: AccordCoreVars.token,
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
    }
}

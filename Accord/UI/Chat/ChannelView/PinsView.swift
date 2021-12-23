//
//  PinsView.swift
//  Accord
//
//  Created by evelyn on 2021-12-21.
//

import Foundation
import SwiftUI
import Combine

struct PinsView: View {
    var guildID: String
    var channelID: String
    @State var pins: [Message] = []
    @State var bag = Set<AnyCancellable>()
    var body: some View {
        List($pins, id: \.id) { $message in
            MessageCellView(message: $message, nick: nil, replyNick: nil, pronouns: nil, role: Binding.constant(nil), replyRole: Binding.constant(nil), replyingTo: Binding.constant(nil))
        }
        .onAppear(perform: {
            messageFetchQueue.async {
                // https://discord.com/api/v9/channels/831692717397770272/pins
                RequestPublisher.fetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/pins"), headers: Headers(
                    userAgent: discordUserAgent,
                    token: AccordCoreVars.shared.token,
                    type: .GET,
                    discordHeaders: true,
                    referer: "https://discord.com/channels/\(guildID)/\(channelID)"
                ))
                .replaceError(with: [])
                .sink { messages in
                    DispatchQueue.main.async {
                        self.pins = messages
                    }
                }
                .store(in: &bag)
            }
        })
    }
}

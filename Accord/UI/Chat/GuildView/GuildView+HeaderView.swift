//
//  GuildView+HeaderView.swift
//  GuildView+HeaderView
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI


extension GuildView {
    var headerView: some View {
        return HStack {
            VStack(alignment: .leading) {
                Text("This is the beginning of #\(channelName)")
                    .font(.title2)
                    .fontWeight(.bold)
                Button("Load more messages") {
                    let extraMessageLoadQueue = DispatchQueue(label: "Message Load Queue", attributes: .concurrent)
                    extraMessageLoadQueue.async {
                        Request.fetch([Message].self, url: URL(string: "\(rootURL)/channels/\(channelID)/messages?before=\(viewModel.messages.last?.id ?? "")&limit=50"), headers: Headers(
                            userAgent: discordUserAgent,
                            token: AccordCoreVars.shared.token,
                            type: .GET,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
                        )) { messages in
                            if let messages = messages {
                                // MARK: - Channel setup after messages loaded.
                                DispatchQueue.main.async {
                                    for (index, message) in messages.enumerated() {
                                        if message != messages.last {
                                            message.lastMessage = messages[index + 1]
                                        }
                                    }
                                    self.popup.append(contentsOf: Array.init(repeating: false, count: 50))
                                    self.viewModel.messages = messages
                                    self.viewModel.messages.insert(contentsOf: messages, at: messages.count)
                                }
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical)
        .rotationEffect(.radians(.pi))
        .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

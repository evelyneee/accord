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
        return VStack(alignment: .leading) {
            HStack {
                Group {
                    if typing.count == 1 && !(typing.isEmpty) {
                        Text("\(typing.map{ "\($0)" }.joined(separator: ", ")) is typing..")
                    } else if !(typing.isEmpty) {
                        Text("\(typing.joined(separator: ", ")) are typing...")
                    }
                }
                .padding(4)
                .lineLimit(0)
                .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow))
                .cornerRadius(5)
                if let replied = replyingTo {
                    Text("replying to \(replied.author?.username ?? "")")
                        .padding(4)
                        .lineLimit(0)
                        .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow))
                        .cornerRadius(5)
                }
            }
            ChatControls(guildID: Binding.constant(guildID), channelID: Binding.constant(channelID), chatText: Binding.constant("Message #\(channelName)"), replyingTo: $replyingTo, users: Binding.constant(self.viewModel.messages.compactMap { $0.author }))
        }
        .padding()
    }
}

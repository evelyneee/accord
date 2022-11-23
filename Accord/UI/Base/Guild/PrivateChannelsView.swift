//
//  PrivateChannelsView.swift
//  Accord
//
//  Created by evelyn on 2022-05-17.
//

import SwiftUI

extension ServerListView {
    var privateChannelsView: some View {
        List(selection: self.$appModel.selectedChannel) {
            ForEach(self.$appModel.privateChannels, id: \.self) { $channel in
                PlatformNavigationLink(
                    item: channel,
                    selection: self.$appModel.selectedChannel,
                    destination: {
                        NavigationLazyView(
                            ChannelView(self.$appModel.selectedChannel)
                                .onAppear {
                                    let channelID = channel.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [channelID] in
                                        if self.appModel.selectedChannel?.id == channelID {
                                            self.appModel.selectedChannel?.read_state?.mention_count = 0
                                            self.appModel.selectedChannel?.read_state?.last_message_id = channel.last_message_id
                                        }
                                    })
                                }
                                .onDisappear { [channel] in
                                    channel.read_state?.mention_count = 0
                                    channel.read_state?.last_message_id = channel.last_message_id
                                }
                        )
                    }
                )
                .onAppear {
                    if UserDefaults.standard.string(forKey: "AccordChannelDMs") == channel.id {
                        self.appModel.selectedChannel = channel
                    }
                }
                .contextMenu {
                    Button("Copy Channel ID") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(channel.id, forType: .string)
                    }
                    Button("Close DM") {
                        let headers = Headers(
                            contentType: nil,
                            token: Globals.token,
                            type: .DELETE,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/@me",
                            empty: true
                        )
                        Request.ping(url: URL(string: "\(rootURL)/channels/\(channel.id)"), headers: headers)
                        self.appModel.selectedChannel = nil
                        guard let index = appModel.privateChannels[indexOf: channel.id] else { return }
                        appModel.privateChannels.remove(at: index)
                    }
                    Button("Mark as read") {
                        channel.read_state?.mention_count = 0
                        channel.read_state?.last_message_id = channel.last_message_id
                    }
                    Button("Open in new window") {
                        showWindow(channel, globals: self.appModel)
                    }
                }
            }
        }

    }
}

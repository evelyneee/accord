//
//  PrivateChannelsView.swift
//  Accord
//
//  Created by evelyn on 2022-05-17.
//

import SwiftUI

struct PrivateChannelsView: View {
    var privateChannels: [Channel]
    @Binding var selection: Int?
    @StateObject var viewUpdater: ServerListView.UpdateView
    var body: some View {
        ForEach(privateChannels, id: \.id) { channel in
            NavigationLink (
                tag: Int(channel.id) ?? 0,
                selection: self.$selection,
                destination: {
                    NavigationLazyView(
                        ChannelView(channel)
                            .equatable()
                            .onAppear {
                                let prevCount = channel.read_state?.mention_count
                                channel.read_state?.mention_count = 0
                                channel.read_state?.last_message_id = channel.last_message_id
                                if prevCount != 0 { self.viewUpdater.updateView() }
                            }
                            .onDisappear {
                                let prevCount = channel.read_state?.mention_count
                                channel.read_state?.mention_count = 0
                                channel.read_state?.last_message_id = channel.last_message_id
                                if prevCount != 0 { self.viewUpdater.updateView() }
                            }
                    )
                },
                label: {
                    ServerListViewCell(channel: channel, updater: self.viewUpdater)
                        .animation(nil, value: UUID())
                }
            )
            .contextMenu {
                Button("Copy Channel ID") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(channel.id, forType: .string)
                }
                Button("Close DM") {
                    let headers = Headers(
                        userAgent: discordUserAgent,
                        contentType: nil,
                        token: AccordCoreVars.token,
                        type: .DELETE,
                        discordHeaders: true,
                        referer: "https://discord.com/channels/@me",
                        empty: true
                    )
                    Request.ping(url: URL(string: "\(rootURL)/channels/\(channel.id)"), headers: headers)
                    guard let index = ServerListView.privateChannels[indexOf: channel.id] else { return }
                    ServerListView.privateChannels.remove(at: index)
                }
                Button("Mark as read") {
                    channel.read_state?.mention_count = 0
                    channel.read_state?.last_message_id = channel.last_message_id
                }
                Button("Open in new window") {
                    showWindow(channel)
                }
            }
        }
    }
}

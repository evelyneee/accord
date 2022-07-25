//
//  PrivateChannelsView.swift
//  Accord
//
//  Created by evelyn on 2022-05-17.
//

import SwiftUI

struct PrivateChannelsView: View {
    
    @Binding var selection: Int?
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    var body: some View {
        ForEach($appModel.privateChannels, id: \.id) { $channel in
            NavigationLink(
                tag: Int(channel.id) ?? 0,
                selection: self.$selection,
                destination: {
                    NavigationLazyView(
                        ChannelView(channel)
                            .equatable()
                            .environmentObject(self.appModel)
                            .onAppear {
                                channel.read_state?.mention_count = 0
                                channel.read_state?.last_message_id = channel.last_message_id
                            }
                            .onDisappear {
                                channel.read_state?.mention_count = 0
                                channel.read_state?.last_message_id = channel.last_message_id
                            }
                    )
                },
                label: {
                    ServerListViewCell(channel: $channel)
                        .environmentObject(self.appModel)
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
                        contentType: nil,
                        token: Globals.token,
                        type: .DELETE,
                        discordHeaders: true,
                        referer: "https://discord.com/channels/@me",
                        empty: true
                    )
                    Request.ping(url: URL(string: "\(rootURL)/channels/\(channel.id)"), headers: headers)
                    self.selection = nil
                    guard let index = appModel.privateChannels[indexOf: channel.id] else { return }
                    appModel.privateChannels.remove(at: index)
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

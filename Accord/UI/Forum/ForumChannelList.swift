//
//  ForumChannelList.swift
//  Accord
//
//  Created by evelyn on 2022-06-17.
//

import SwiftUI

struct ThreadSearchResult: Decodable {
    var firstMessages: [Message]
    var hasMore: Bool
    var threads: [Channel]
    var totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case firstMessages = "first_messages"
        case hasMore = "has_more"
        case threads
        case totalResults = "total_results"
    }
}

final class ForumChannelListModel: ObservableObject {
    
    @Published var channels: [(channel: Channel, message: Message)] = .init()
    
    func loadChannels(for forumID: String) {
        let url = root
            .appendingPathComponent("channels")
            .appendingPathComponent(forumID)
            .appendingPathComponent("threads")
            .appendingPathComponent("search")
            .appendingQueryParameters([
                "archived":"true",
                "sort_by": "last_message_time",
                "sort_order": "desc",
                "limit": "25",
                "offset": "0"
            ])
        RequestPublisher.fetch(ThreadSearchResult.self, url: url, headers: Headers(
            userAgent: discordUserAgent,
            token: Globals.token,
            type: .GET,
            discordHeaders: true,
            referer: "https://discord.com/" + "@me/" + "channels/" + forumID
        ))
        .map {
            Array(zip($0.threads, $0.firstMessages))
        }
        .map {
            $0.map {
                var new = $0
                new.0.overridePermissions = true
                return new
            }
        }
        .replaceError(with: [])
        .assign(to: &self.$channels)
    }
}


struct ForumChannelList: View {
    
    var forumChannel: Channel
    @State var selectedChannel: Channel? = nil
    @StateObject var model = ForumChannelListModel()
    
    var body: some View {
        NavigationView {
            List(self.model.channels, id: \.channel.id) { channel, message in
                NavigationLink(tag: channel, selection: self.$selectedChannel, destination: {
                    if let selectedChannel {
                        NavigationLazyView(
                            ChannelView(selectedChannel).equatable()
                        )
                    }
                }, label: {
                    GroupBox {
                        VStack(alignment: .leading) {
                            Text(channel.computedName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(0)
                            Text(message.content)
                                .lineLimit(0)
                                .font(.chatTextFont)
                                .foregroundColor(.secondary)
                        }
                        .padding(7)
                    }
                })
            }
            .onAppear {
                self.model.loadChannels(for: self.forumChannel.id)
            }
            .frame(minWidth: 400)
        }
        .navigationTitle(Text("#" + self.forumChannel.computedName))
    }
}

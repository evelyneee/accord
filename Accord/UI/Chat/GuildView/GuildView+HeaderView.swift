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
                        Networking<[Message]>().fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages?limit=50"), headers: Headers(
                            userAgent: discordUserAgent,
                            token: AccordCoreVars.shared.token,
                            type: .GET,
                            discordHeaders: true,
                            referer: "\(rootURL)/channels/\(guildID)/\(channelID)"
                        )) { messages in
                            if let messages = messages {
                                // MARK: - Channel setup after messages loaded.

                                for (index, message) in messages.enumerated() {
                                    if message != messages.last {
                                        message.lastMessage = messages[index + 1]
                                    }
                                }
                                self.messages = messages
                                let authorArray = Array(NSOrderedSet(array: messages.compactMap { $0.author! }))
                                for user in authorArray as! [User] {
                                    if let url = URL(string: "https://cdn.discordapp.com/avatars/\(user.id)/\(user.avatar ?? "").png?size=80") {
                                        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 5.0)
                                        if let data = cache.cachedResponse(for: request)?.data {
                                            user.pfp = data
                                        } else {
                                            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                                if let data = data, let response = response {
                                                    let cachedData = CachedURLResponse(response: response, data: data)
                                                    cache.storeCachedResponse(cachedData, for: request)
                                                    user.pfp = data
                                                }
                                            }).resume()
                                        }
                                    }
                                }
                                let replyArray = Array(NSOrderedSet(array: messages.compactMap { $0.referenced_message?.author }))
                                for user in replyArray as! [User] {
                                    if let url = URL(string: "https://cdn.discordapp.com/avatars/\(user.id)/\(user.avatar ?? "").png?size=80") {
                                        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 5.0)
                                        if let data = cache.cachedResponse(for: request)?.data {
                                            user.pfp = data
                                        } else {
                                            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                                if let data = data, let response = response {
                                                    let cachedData = CachedURLResponse(response: response, data: data)
                                                    cache.storeCachedResponse(cachedData, for: request)
                                                    user.pfp = data
                                                }
                                            }).resume()
                                        }
                                    }
                                }
                                self.messages.insert(contentsOf: messages, at: messages.count)
                            }

                        }
                    }

                    print("piss shit and cum")

                }
            }
            Spacer()
        }
        .padding(.vertical)
        .rotationEffect(.radians(.pi))
        .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

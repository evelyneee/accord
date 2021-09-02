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
                    concurrentQueue.async {
                        NetworkHandling.shared.requestData(url: "\(rootURL)/channels/\(channelID)/messages?before=\(data.last?.id ?? "")&limit=50", token: AccordCoreVars.shared.token, json: true, type: .GET, bodyObject: [:]) { success, rawData in
                            if success == true {
                                do {
                                    let newData = try JSONDecoder().decode([Message].self, from: rawData!)
                                    print("cock and balls \(data.count)")
                                    let authorArray = Array(NSOrderedSet(array: newData.compactMap { $0.author! }))
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
                                    let replyArray = Array(NSOrderedSet(array: newData.compactMap { $0.referenced_message?.author }))
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
                                    data.insert(contentsOf: newData, at: data.count)
                                } catch {
                                }
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

//
//  GuildView+SecondLoad.swift
//  GuildView+SecondLoad
//
//  Created by evelyn on 2021-08-23.
//

import Foundation

extension GuildView {
    // MARK: - Second stage of channel loading
    func performSecondStageLoad() {
        if guildID != "@me" {
            var allUserIDs = Array(NSOrderedSet(array: data.map { $0.author?.id ?? "" })) as! Array<String>
            getCachedMemberChunk()
            for (index, item) in allUserIDs.enumerated() {
                if Array(WebSocketHandler.shared.cachedMemberRequest.keys).contains("\(guildID)$\(item)") {
                    if Array<Int>(allUserIDs.indices).contains(index) {
                        allUserIDs.remove(at: index)
                    }
                }
            }
            if !(allUserIDs.isEmpty) {
                WebSocketHandler.shared.getMembers(ids: allUserIDs, guild: guildID) { success, users in
                    if success {
                        for person in users {
                            nicks[(person?.user.id ?? "")] = person?.nick ?? ""
                        }
                    }
                }
            }
        }
        let authorArray = Array(NSOrderedSet(array: data.compactMap { $0.author! }))
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
        let replyArray = Array(NSOrderedSet(array: data.compactMap { $0.referenced_message?.author }))
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

    }

}

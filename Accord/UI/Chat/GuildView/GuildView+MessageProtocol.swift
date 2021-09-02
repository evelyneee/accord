//
//  GuildView+MessageProtocol.swift
//  GuildView+MessageProtocol
//
//  Created by evelyn on 2021-08-23.
//

import Foundation

extension GuildView: MessageControllerDelegate {
    func sendMessage(msg: Data, channelID: String?) {
        // Recieved a message from backend
        webSocketQueue.async {
            guard channelID != nil else { return }
            if channelID! == self.channelID {
                sending = false
                guard let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: msg) else { return }
                guard let message = gatewayMessage.d else { return }
                if let url = URL(string: "https://cdn.discordapp.com/avatars/\(message.author?.id ?? "")/\(message.author?.avatar ?? "").png?size=80") {
                    let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 5.0)
                    if let data = cache.cachedResponse(for: request)?.data {
                        message.author?.pfp = data
                    } else {
                        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                            if let data = data, let response = response {
                            let cachedData = CachedURLResponse(response: response, data: data)
                                cache.storeCachedResponse(cachedData, for: request)
                                message.author?.pfp = data
                            }
                        }).resume()
                    }
                }
                if message.referenced_message != nil {
                    if let url = URL(string: "https://cdn.discordapp.com/avatars/\(message.referenced_message?.author?.id ?? "")/\(message.referenced_message?.author?.avatar ?? "").png?size=80") {
                        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 5.0)
                        if let data = cache.cachedResponse(for: request)?.data {
                            message.referenced_message?.author?.pfp = data
                        } else {
                            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                if let data = data, let response = response {
                                let cachedData = CachedURLResponse(response: response, data: data)
                                    cache.storeCachedResponse(cachedData, for: request)
                                    message.referenced_message?.author?.pfp = data
                                }
                            }).resume()
                        }
                    }
                }
                data.insert(message, at: 0)
            }
        }
    }
    func editMessage(msg: Data, channelID: String?) {
        // Recieved a message from backend
        webSocketQueue.async {
            if channelID == self.channelID {
                guard channelID != nil else { return }
                if channelID! == self.channelID {
                    let currentUIDDict = data.map { $0.id }
                    guard let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: msg) else { return }
                    guard let message = gatewayMessage.d else { return }
                    data[(currentUIDDict).firstIndex(of: message.id) ?? 0] = message
                }
            }

        }
    }
    func deleteMessage(msg: Data, channelID: String?) {
        if channelID == self.channelID {
            webSocketQueue.async {
                let currentUIDDict = data.map { $0.id }
                guard let gatewayMessage = try? JSONDecoder().decode(GatewayDeletedMessage.self, from: msg) else { return }
                guard let message = gatewayMessage.d else { return }
                guard let index = (currentUIDDict).firstIndex(of: message.id) else { return }
                data.remove(at: index)
            }
        }
    }
    func typing(msg: [String: Any], channelID: String?) {
        webSocketQueue.async {
            if channelID == self.channelID {
                print("[Accord] typing 2")
                if !(typing.contains(msg["user_id"] as? String ?? "")) {
                    print("[Accord] typing 3")
                    let memberData = try! JSONSerialization.data(withJSONObject: msg, options: [])
                    let memberDecodable = try! JSONDecoder().decode(TypingEvent.self, from: memberData)
                    guard let nick = memberDecodable.member?.nick else {
                        print("[Accord] typing 4", memberDecodable.member?.user.username ?? "")
                        typing.append(memberDecodable.member?.user.username ?? "")
                        DispatchQueue.global().asyncAfter(deadline: .now() + 7, execute: {
                            typing.remove(at: typing.firstIndex(of: memberDecodable.member?.user.username ?? "") ?? 0)
                        })
                        return
                    }
                    print("[Accord] typing 4", nick)
                    typing.append(nick)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
                        typing.remove(at: typing.firstIndex(of: (nick)) ?? 0)
                    })
                }
            }

        }

    }
    func sendMemberChunk(msg: Data) {
        webSocketQueue.async {
            guard let chunk = try? JSONDecoder().decode(GuildMemberChunkResponse.self, from: msg) else { return }
            guard let users = chunk.d?.members else { return }
            ChannelMembers.shared.channelMembers[self.channelID] = Dictionary(uniqueKeysWithValues: zip(users.compactMap { $0!.user.id }, users.compactMap { $0?.nick ?? $0!.user.username }))
            for person in users {
                let nickname = person?.nick ?? person?.user.username ?? ""
                nicks[(person?.user.id ?? "")] = nickname
                var rolesTemp: [String] = []
                for _ in 0..<100 {
                    rolesTemp.append("empty")
                }
                for role in (person?.roles ?? []) {
                    rolesTemp[roleColors[role]?.1 ?? 0] = role
                }
                rolesTemp = rolesTemp.compactMap { role -> String? in
                    if role == "empty" {
                        return nil
                    } else {
                        return role
                    }
                }
                rolesTemp = rolesTemp.reversed()
                roles[(person?.user.id ?? "")] = rolesTemp
            }
        }
    }
    func sendWSError(msg: String) {
        error = msg
    }
}

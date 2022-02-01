//
//  Gateway+Receive.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Combine
import Foundation

extension Gateway {
    final func receive() {
        ws.receive { [weak self] result in
            switch result {
            case let .success(message):
                switch message {
                case let .string(text):
                    if let textData = text.data(using: .utf8) {
                        guard let payload = self?.decodePayload(payload: textData), let op = payload["op"] as? Int else { return }
                        guard let s = payload["s"] as? Int else {
                            if op == 11 {
                                // no seq + op 11 means a hearbeat was done successfully
                                print("Heartbeat successful")
                                self?.pendingHeartbeat = false
                                self?.receive()
                            } else {
                                // disconnected?
                                try? self?.reconnect()
                            }
                            return
                        }
                        self?.seq = s
                        guard let t = payload["t"] as? String else {
                            self?.receive()
                            return
                        }
                        print("t: \(t)")
                        switch t {
                        case "READY":
                            let path = FileManager.default.urls(for: .cachesDirectory,
                                                                in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                            try? textData.write(to: path)
                            guard let structure = try? JSONDecoder().decode(GatewayStructure.self, from: textData) else { break }
                            releaseModePrint(" Gateway ready (\(structure.d.v ?? 0), \(structure.d.user.username)#\(structure.d.user.discriminator))")
                            self?.session_id = structure.d.session_id

                        // MARK: Channel Event Handlers

                        case "CHANNEL_CREATE": break
                        case "CHANNEL_UPDATE": break
                        case "CHANNEL_DELETE": break

                        // MARK: Guild Event Handlers

                        case "GUILD_CREATE": print("guild created")
                        case "GUILD_DELETE": break
                        case "GUILD_MEMBER_ADD": break
                        case "GUILD_MEMBER_REMOVE": break
                        case "GUILD_MEMBER_UPDATE": break
                        case "GUILD_MEMBERS_CHUNK":
                            DispatchQueue.main.async {
                                MessageController.shared.sendMemberChunk(msg: textData)
                            }

                        // MARK: Invite Event Handlers

                        case "INVITE_CREATE": break
                        case "INVITE_DELETE": break

                        // MARK: Message Event Handlers

                        case "MESSAGE_CREATE":
                            guard let dict = payload["d"] as? [String: Any] else { break }
                            if let channelID = dict["channel_id"] as? String, let author = dict["author"] as? [String: Any], let id = author["id"] as? String, id == user_id {
                                MessageController.shared.sendMessage(msg: textData, channelID: channelID, isMe: true)
                            } else if let channelID = dict["channel_id"] as? String {
                                MessageController.shared.sendMessage(msg: textData, channelID: channelID)
                            }
                            guard let mentions = dict["mentions"] as? [[String: Any]] else { break }
                            let ids = mentions.compactMap { $0["id"] as? String }
                            print("notification 1")
                            let guild_id = dict["guild_id"] as? String ?? "@me"
                            guard let channel_id = dict["channel_id"] as? String else { break }
                            print("notification 2")
                            guard let author = dict["author"] as? [String: Any] else { break }
                            guard let username = author["username"] as? String else { break }
                            guard let userID = author["id"] as? String else { break }
                            print("notification 3")
                            guard let content = dict["content"] as? String else { break }
                            if ids.contains(user_id) {
                                print("notification")
                                showNotification(title: username, subtitle: content)
                                MentionSender.shared.addMention(guild: guild_id, channel: channel_id)
                            } else if Notifications.privateChannels.contains(channel_id), userID != user_id {
                                showNotification(title: username, subtitle: content)
                                MentionSender.shared.addMention(guild: guild_id, channel: channel_id)
                            }
                        case "MESSAGE_UPDATE":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.editMessage(msg: textData, channelID: channelid)
                            }
                        case "MESSAGE_DELETE":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.deleteMessage(msg: textData, channelID: channelid)
                            }
                        case "MESSAGE_REACTION_ADD": print("something was created")
                        case "MESSAGE_REACTION_REMOVE": print("something was created")
                        case "MESSAGE_REACTION_REMOVE_ALL": print("something was created")
                        case "MESSAGE_REACTION_REMOVE_EMOJI": print("something was created")

                        // MARK: Presence Event Handlers

                        case "PRESENCE_UPDATE": print(text)
                        case "TYPING_START":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.typing(msg: data, channelID: channelid)
                            }
                        case "USER_UPDATE": break
                        case "READY_SUPPLEMENTAL": break
                        case "MESSAGE_ACK": print(text)
                        case "GUILD_MEMBER_LIST_UPDATE":
//                            do {
//                                let list = try JSONDecoder().decode(MemberListUpdate.self, from: textData)
//                                MessageController.shared.sendMemberList(msg: list)
//                            } catch { }
                            break
                        default: break
                        }
                    }
                    self?.receive() // call back the function, creating a loop
                case .data: break
                @unknown default: break
                }
            case let .failure(error):
                releaseModePrint(" Error when receiving loop \(error)")
                print("RECONNECT")
                MentionSender.shared.sendWSError(error: error)
            }
        }
    }
}

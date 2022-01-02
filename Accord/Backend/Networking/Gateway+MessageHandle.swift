//
//  Gateway+Receive.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation
import Combine

extension Gateway {
        
    func handleMessage(textData: Data) {
        guard let payload = self.decodePayload(payload: textData), let op = payload["op"] as? Int else { return }
        guard let s = payload["s"] as? Int else {
            if op == 11 {
                // no seq + op 11 means a hearbeat was done successfully
                print("Heartbeat successful")
                self.pendingHeartbeat = false
            } else {
                // disconnected?
                try? self.reconnect()
            }
            return
        }
        self.seq = s
        guard let t = payload["t"] as? String else {
            return
        }
        switch t {
        case "READY": break
        // MARK: Channel Event Handlers
        case "CHANNEL_CREATE": break
        case "CHANNEL_UPDATE": break
        case "CHANNEL_DELETE": break

        // MARK: Guild Event Handlers
        case "GUILD_CREATE": print("guild created"); break
        case "GUILD_DELETE": break
        case "GUILD_MEMBER_ADD": break
        case "GUILD_MEMBER_REMOVE": break
        case "GUILD_MEMBER_UPDATE": break
        case "GUILD_MEMBERS_CHUNK":
            memberChunkSubject.send(textData)
        // MARK: Invite Event Handlers
        case "INVITE_CREATE": break
        case "INVITE_DELETE": break

        // MARK: Message Event Handlers
        case "MESSAGE_CREATE":
            guard let dict = payload["d"] as? [String: Any] else { break }
            if let channelID = dict["channel_id"] as? String, let author = dict["author"] as? [String: Any], let id = author["id"] as? String, id == user_id {
                self.messageSubject.send((textData, channelID, true))
            } else if let channelID = dict["channel_id"] as? String {
                self.messageSubject.send((textData, channelID, false))
            }
            guard let mentions = dict["mentions"] as? [[String: Any]] else { break }
            let ids = mentions.compactMap { $0["id"] as? String }
            let guild_id = dict["guild_id"] as? String ?? "@me"
            guard let channel_id = dict["channel_id"] as? String else { break }
            guard let author = dict["author"] as? [String: Any] else { break }
            guard let username = author["username"] as? String else { break }
            guard let userID = author["id"] as? String else { break }
            guard let content = dict["content"] as? String else { break }
            if ids.contains(user_id) {
                print("Sending notification")
                showNotification(title: username, subtitle: content)
                MentionSender.shared.addMention(guild: guild_id, channel: channel_id)
            } else if Notifications.privateChannels.contains(channel_id) && userID != user_id {
                showNotification(title: username, subtitle: content)
                MentionSender.shared.addMention(guild: guild_id, channel: channel_id)
            }
        case "MESSAGE_UPDATE":
            let data = payload["d"] as! [String: Any]
            if let channelID = data["channel_id"] as? String {
                self.editSubject.send((textData, channelID))
            }
        case "MESSAGE_DELETE":
            let data = payload["d"] as! [String: Any]
            if let channelID = data["channel_id"] as? String {
                deleteSubject.send((textData, channelID))
            }
        case "MESSAGE_REACTION_ADD": print("something was created"); break
        case "MESSAGE_REACTION_REMOVE": print("something was created"); break
        case "MESSAGE_REACTION_REMOVE_ALL": print("something was created"); break
        case "MESSAGE_REACTION_REMOVE_EMOJI": print("something was created"); break

        // MARK: Presence Event Handlers
        case "PRESENCE_UPDATE": break
        case "TYPING_START":
            let data = payload["d"] as! [String: Any]
            if let channelID = data["channel_id"] as? String {
                typingSubject.send((textData, channelID))
            }
        case "USER_UPDATE": break
        case "READY_SUPPLEMENTAL": break
        case "MESSAGE_ACK": break
        case "GUILD_MEMBER_LIST_UPDATE":
            do {
                print(payload)
                let list = try JSONDecoder().decode(MemberListUpdate.self, from: textData)
                self.memberListSubject.send(list)
            } catch {
                print(error, "piss")
            }
        default: break
        }
    }

}

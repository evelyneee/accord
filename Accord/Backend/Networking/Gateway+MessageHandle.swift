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
    
    func handleMessage(event: GatewayEvent) {
        guard let s = event.s else {
            if event.op == 11 {
                // no seq + op 11 means a hearbeat was done successfully
                print("Heartbeat successful")
                self.pendingHeartbeat = false
            } else {
                self.reset()
            }
            return
        }
        self.seq = s
        switch event.t {
        case .ready: break
        case .readySupplemental: break
        case .messageACK: break
        case .sessionsReplace: break
        case .heartbeatACK: break
        case .channelCreate: break
        case .channelUpdate: break
        case .channelDelete: break
        case .guildCreate: break
        case .guildDelete: break
        case .guildMemberAdd: break
        case .guildMemberRemove: break
        case .guildMemberUpdate: break
        case .guildMemberChunk:
            memberChunkSubject.send(event.data)
        case .guildMemberListUpdate:
            do {
                let list = try JSONDecoder().decode(MemberListUpdate.self, from: event.data)
                self.memberListSubject.send(list)
            } catch {
                print(error)
            }
        case .inviteCreate: break
        case .inviteDelete: break
        case .messageCreate:
            guard let message = try? JSONDecoder().decode(GatewayMessage.self, from: event.data).d else { return }
            if let channelID = event.channelID, let author = message.author {
                self.messageSubject.send((event.data, channelID, author.id == user_id))
            }
            let ids = message.mentions.compactMap { $0?.id }
            let guildID = message.guild_id ?? "@me"
            guard let channelID = event.channelID else { break }
            if ids.contains(user_id) {
                print("Sending notification")
                showNotification(title: message.author?.username ?? "Unknown User", subtitle: message.content)
                MentionSender.shared.addMention(guild: guildID, channel: channelID)
            } else if Notifications.privateChannels.contains(channelID) && message.author?.id != user_id {
                showNotification(title: username, subtitle: message.content)
                MentionSender.shared.addMention(guild: guildID, channel: channelID)
            }
        case .messageUpdate:
            if let channelID = event.channelID {
                self.editSubject.send((event.data, channelID))
            }
        case .messageDelete:
            if let channelID = event.channelID {
                deleteSubject.send((event.data, channelID))
            }
        case .messageReactionAdd: break
        case .messageReactionRemove: break
        case .messageReactionRemoveAll: break
        case .messageReactionRemoveEmoji: break
        case .presenceUpdate: break
        case .typingStart:
            print(event.t)
            if let channelID = event.channelID {
                typingSubject.send((event.data, channelID))
            }
        case .userUpdate: break
        case .channelUnreadUpdate: break
        case .threadListSync: break
        case .messageDeleteBulk: break
        case .voiceStateUpdate: break
        case .applicationCommandUpdate: break
        case .applicationCommandPermissionsUpdate: break
        }
    }

}

struct GatewayEvent {
    
    init(data: Data) throws {
        guard let packet = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { throw Gateway.GatewayErrors.eventCorrupted }
        let tString = packet["t"] as? String ?? "HEARTBEAT_ACK"
        guard let t = T.init(rawValue: tString) else { throw Gateway.GatewayErrors.unknownEvent(tString) }
        print("init success")
        self.t = t
        self.s = packet["s"] as? Int
        self.op = packet["op"] as? Int
        self.d = packet["d"] as? [String:Any]
        self.channelID = d?["channel_id"] as? String
        self.data = data
    }
    
    var t: T
    var s: Int?
    var d: [String:Any]?
    var op: Int?
    var channelID: String?
    var data: Data
    
    enum T: String {
        case ready = "READY"
        case readySupplemental = "READY_SUPPLEMENTAL"
        case messageACK = "MESSAGE_ACK"
        case sessionsReplace = "SESSIONS_REPLACE"
        case channelUnreadUpdate = "CHANNEL_UNREAD_UPDATE"
        case heartbeatACK = "HEARTBEAT_ACK"
        
        case channelCreate = "CHANNEL_CREATE"
        case channelUpdate = "CHANNEL_UPDATE"
        case channelDelete = "CHANNEL_DELETE"
        
        case guildCreate = "GUILD_CREATE"
        case guildDelete = "GUILD_DELETE"
        case guildMemberAdd = "GUILD_MEMBER_ADD"
        case guildMemberRemove = "GUILD_MEMBER_REMOVE"
        case guildMemberUpdate = "GUILD_MEMBER_UPDATE"
        case guildMemberChunk = "GUILD_MEMBERS_CHUNK"
        case guildMemberListUpdate = "GUILD_MEMBER_LIST_UPDATE"
        case threadListSync = "THREAD_LIST_SYNC"
        
        case inviteCreate = "INVITE_CREATE"
        case inviteDelete = "INVITE_DELETE"

        case messageCreate = "MESSAGE_CREATE"
        case messageUpdate = "MESSAGE_UPDATE"
        case messageDelete = "MESSAGE_DELETE"
        case messageDeleteBulk = "MESSAGE_DELETE_BULK"
        case messageReactionAdd = "MESSAGE_REACTION_ADD"
        case messageReactionRemove = "MESSAGE_REACTION_REMOVE"
        case messageReactionRemoveAll = "MESSAGE_REACTION_REMOVE_ALL"
        case messageReactionRemoveEmoji = "MESSAGE_REACTION_REMOVE_EMOJI"

        case presenceUpdate = "PRESENCE_UPDATE"
        case typingStart = "TYPING_START"
        case userUpdate = "USER_UPDATE"
        
        case voiceStateUpdate = "VOICE_STATE_UPDATE"
        
        case applicationCommandUpdate = "APPLICATION_COMMAND_UPDATE"
        case applicationCommandPermissionsUpdate = "APPLICATION_COMMAND_PERMISSIONS_UPDATE"
    }
}

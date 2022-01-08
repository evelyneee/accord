//
//  Gateway+Receive.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation
import Combine

extension Gateway {
    func handleMessage(event: GatewayEvent) {
        switch event.op {
        case .heartbeatACK:
            print("Heartbeat successful")
            self.pendingHeartbeat = false
            return
        case .reconnect:
            print("reconnecting..")
        case .hello:
            print("missed hello?")
        case .invalidSession:
            self.hardReset()
        case .heartbeat:
            break
        default: break
        }
        if let s = event.s {
            self.seq = s
        }
        switch event.t {
        case .messageACK: break
        case .sessionsReplace: break
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
            if let channelID = event.channelID {
                typingSubject.send((event.data, channelID))
            }
        case .userUpdate: break
        case .channelUnreadUpdate: break
        case .threadListSync: break
        case .messageDeleteBulk: break
        case .applicationCommandUpdate: break
        case .applicationCommandPermissionsUpdate: break
        default: break
        }
    }

}

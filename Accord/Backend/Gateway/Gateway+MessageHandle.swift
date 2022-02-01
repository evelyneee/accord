//
//  Gateway+Receive.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Combine
import Foundation

extension Gateway {
    func handleMessage(event: GatewayEvent) {
        switch event.op {
        case .heartbeatACK:
            print("Heartbeat successful")
            pendingHeartbeat = false
            return
        case .reconnect:
            print("reconnecting..")
        case .hello:
            print("missed hello?")
        case .invalidSession:
            print(String(data: event.data, encoding: .utf8))
            hardReset()
        default: break
        }
        if let s = event.s {
            seq = s
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
                memberListSubject.send(list)
            } catch {
                print(error)
            }
        case .inviteCreate: break
        case .inviteDelete: break
        case .messageCreate:
            guard let message = try? JSONDecoder().decode(GatewayMessage.self, from: event.data).d else { print("uhhhhh"); return }
            if let channelID = event.channelID, let author = message.author {
                messageSubject.send((event.data, channelID, author.id == user_id))
            }
            let ids = message.mentions.compactMap { $0?.id }
            let guildID = message.guild_id ?? "@me"
            guard let channelID = event.channelID else { print("wat"); break }
            if ids.contains(user_id) || (ServerListView.privateChannels.map(\.id).contains(channelID) && message.author?.id != user_id) {
                print("Sending notification")
                let guildArray = ServerListView.folders.map { $0.guilds.filter { $0.id == message.guild_id } }
                let channelArray = ServerListView.folders.map { $0.guilds.compactMap { $0.channels?.filter { $0.id == channelID } } }
                var joined: [Channel] = Array(Array(Array(channelArray).joined()).joined())
                joined.append(contentsOf: ServerListView.privateChannels.filter { $0.id == channelID })
                let joinedGuilds: Guild? = Array(guildArray.joined()).first
                print(message.guild_id)
                showNotification(title: message.author?.username ?? "Unknown User", subtitle: joinedGuilds == nil ? joined.first?.name ?? "Direct Messages" : "#\(joined.first?.computedName ?? "") • \(joinedGuilds?.name ?? "")", description: message.content)
                MentionSender.shared.addMention(guild: guildID, channel: channelID)
            }
        case .messageUpdate:
            if let channelID = event.channelID {
                editSubject.send((event.data, channelID))
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

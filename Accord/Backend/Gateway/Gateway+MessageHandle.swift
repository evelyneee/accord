//
//  Gateway+Receive.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Combine
import Foundation

extension Gateway {
    func handleMessage(event: GatewayEvent) throws {
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
            // let channel = try JSONDecoder().decode(GatewayEventContent<Channel>.self, from: event.data)
        case .channelUpdate: break
        case .channelDelete: break
        case .guildCreate:
            let guild = try JSONDecoder().decode(GatewayEventContent<Guild>.self, from: event.data)
            let folder = GuildFolder(guild_ids: [guild.d.id])
            folder.guilds.append(guild.d)
            ServerListView.folders.append(folder)
        case .guildDelete:
            print(String(data: event.data, encoding: .utf8))
        case .guildMemberAdd: break
        case .guildMemberRemove: break
        case .guildMemberUpdate: break
        case .guildMemberChunk:
            memberChunkSubject.send(event.data)
        case .guildMemberListUpdate:
            let list = try JSONDecoder().decode(MemberListUpdate.self, from: JSONSerialization.data(withJSONObject: ["d": event.d]))
            memberListSubject.send(list)
        case .inviteCreate: break
        case .inviteDelete: break
        case .messageCreate:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
            let message = try decoder.decode(GatewayEventContent<Message>.self, from: event.data).d
            if let channelID = event.channelID, let author = message.author {
                messageSubject.send((event.data, channelID, author.id == user_id))
            }
            guard message.author?.id != user_id else { return }
            let ids = message.mentions.compactMap { $0?.id }
            let guildID = message.guild_id ?? "@me"
            guard let channelID = event.channelID else { print("wat"); break }
            MentionSender.shared.newMessage(in: channelID, with: message.id, isDM: message.guild_id == nil)
            if ids.contains(user_id) || (ServerListView.privateChannels.map(\.id).contains(channelID) && message.author?.id != user_id) {
                print("Sending notification")
                let guildArray = ServerListView.folders.map { $0.guilds.filter { $0.id == message.guild_id } }
                let channelArray = ServerListView.folders.map { $0.guilds.compactMap { $0.channels?.filter { $0.id == channelID } } }
                var joined: [Channel] = Array(Array(Array(channelArray).joined()).joined())
                joined.append(contentsOf: ServerListView.privateChannels.filter { $0.id == channelID })
                let joinedGuilds: Guild? = Array(guildArray.joined()).first
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
        case .presenceUpdate:
            let event = try JSONDecoder().decode(GatewayEventContent<PresenceUpdate>.self, from: event.data)
            self.presencePipeline[event.d.user.id]?.send(event.d)
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
        case .guildApplicationCommandsUpdate:
            print("uwu")
            if let guildID = event.guildID {
                let commands = try JSONDecoder().decode(
                    SlashCommandStorage.GuildApplicationCommandsUpdateEvent.self,
                    from: event.data
                )
                let userKeyMap = commands.d.applications.generateKeyMap()
                SlashCommandStorage.commands[guildID] = commands.d.application_commands
                    .map { command -> SlashCommandStorage.Command in
                        print(command)
                        if let avatar = commands.d.applications[command.application_id, userKeyMap]?.icon {
                            command.avatar = avatar
                            return command
                        }
                        return command
                    }
            }
        default: break
        }
    }
}

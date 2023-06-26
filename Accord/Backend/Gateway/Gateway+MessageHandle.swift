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
            hardReset()
        default: break
        }
        if let s = event.s {
            seq = s
        }
                        
        switch event.t {
        case .messageACK: break
        case .sessionsReplace: break
        case .channelCreate:
            let channel = try JSONDecoder().decode(GatewayEventContent<Channel>.self, from: event.data)
            print("success 1")
            if channel.d.guild_id == nil { // is a dm
                print("success")
                DispatchQueue.main.async {
                    Storage.globals?.privateChannels.insert(channel.d, at: 0)
                }
            }
        case .channelUpdate: break
        case .channelDelete: break
        case .guildCreate:
            let guild = try JSONDecoder().decode(GatewayEventContent<Guild>.self, from: event.data)
            let folder = GuildFolder(guild_ids: [guild.d.id])
            folder.guilds.append(guild.d)
            Task {
                AppGlobals.newItemPublisher.send((nil, folder))
            }
        case .guildDelete: break
        case .guildMemberAdd: break
        case .guildMemberRemove: break
        case .guildMemberUpdate: break
        case .guildMemberChunk:
            memberChunkSubject.send(event.data)
        case .guildMemberListUpdate:
            print("GOT UPDATE OBJECT")
            let list = try JSONDecoder().decode(MemberListUpdate.self, from: JSONSerialization.data(withJSONObject: ["d": event.d]))
            dump(list)
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
            DispatchQueue.main.async {
                guard let channelID = event.channelID, Storage.globals?.selectedChannel?.id == channelID else { return }
                Storage.globals?.newMessage(in: channelID, message: message)
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
            presencePipeline[event.d.user.id]?.send(event.d)
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
        case .voiceServerUpdate: break
//            print(event.d)
//            let token = event.d?["token"] as? String ?? ""
//            guard let endpoint = event.d?["endpoint"] as? String else { return }
//
//            let vcSocket = try? RTCSocket(
//                url: URL(string: "wss://" + endpoint.dropLast(4)),
//                token: token,
//                guildID: "825437365027864578",
//                channelID: ""
//            )
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
                        if let avatar = commands.d.applications[keyed: command.application_id, userKeyMap]?.icon {
                            command.avatar = avatar
                            return command
                        }
                        print(event.data)
                        return command
                    }
            }
        default: break
        }
    }
}

//
//  GatewayEvent.swift
//  Accord
//
//  Created by evelyn on 2022-01-04.
//

import Foundation

struct GatewayEvent {
    init(data: Data) throws {
        guard let packet = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { throw Gateway.GatewayErrors.eventCorrupted }
        let tString = packet["t"] as? String ?? "HEARTBEAT_ACK"
        guard let t = T(rawValue: tString) else { throw Gateway.GatewayErrors.unknownEvent(tString) }
        self.t = t
        s = packet["s"] as? Int
        if let op = packet["op"] as? Int {
            self.op = Opcode(rawValue: op)
        } else {
            op = nil
        }
        d = packet["d"] as? [String: Any]
        channelID = d?["channel_id"] as? String
        guildID = d?["guild_id"] as? String
        self.data = data
    }

    var t: T
    var s: Int?
    var d: [String: Any]?
    var op: Opcode?
    var channelID: String?
    var guildID: String?
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
        case threadUpdate = "THREAD_UPDATE"
        
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

        case guildApplicationCommandsUpdate = "GUILD_APPLICATION_COMMANDS_UPDATE"
    }

    enum Opcode: Int {
        case dispatch = 0, heartbeat, identify, presenceUpdate,
             voiceStateUpdate, unknown, resume, reconnect, guildMemberRequest,
             invalidSession, hello, heartbeatACK, guildSync,
             privateChannelSubscribe, guildSubscribe
    }
}

//
//  Permissions.swift
//  Accord
//
//  Created by evelyn on 2022-02-16.
//

import Foundation

enum Permissions: Int {
    case createInstantInvite   = 0
    case kickMembers           = 1
    case banMembers            = 2
    case administrator         = 3
    case manageChannels        = 4
    case manageGuild           = 5
    case addReactions          = 6
    case viewAuditLog          = 7
    case prioritySpeaker       = 8
    case stream                = 9
    case readMessages          = 10
    case sendMessages          = 11
    case sendTTSMessages       = 12
    case manageMessages        = 13
    case embedLinks            = 14
    case attachFiles           = 15
    case readMessageHistory    = 16
    case mentionEveryone       = 17
    case externalEmoji         = 18
    case viewGuildInsights     = 19
    case connectToVoice        = 20
    case speakInVoice          = 21
    case muteMembers           = 22
    case deafenMembers         = 23
    case moveMembers           = 24
    case useVoiceActivation    = 25
    case changeNickname        = 26
    case manageNicknames       = 27
    case manageRoles           = 28
    case manageWebhooks        = 29
    case manageEmoji           = 30
    case useSlashCommands      = 31
    case requestToSpeak        = 32
    case manageEvents          = 33
    case manageThreads         = 34
    case createPublicThreads   = 35
    case createPrivateThreads  = 36
    case externalStickers      = 37
    case sendMessagesInThreads = 38
    
    static func getValues(for permissions: Int) -> [Self] {
        var permissionsArray: [Self?] = .init()
        for permission in 0..<40 {
            if permissions & 1 << permission == 1 << permission {
                permissionsArray.append(Self.init(rawValue: permission))
            }
        }
        return permissionsArray.compactMap(\.self)
    }
}

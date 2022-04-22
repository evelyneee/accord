//
//  Permissions.swift
//  Accord
//
//  Created by evelyn on 2022-02-16.
//

import Foundation

struct Permissions: Decodable, OptionSet {
    
    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }
    
    init(_ rawValue: Int64) {
        self.init(rawValue: rawValue)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        guard let integer = Int64(stringValue) else { throw Self.PermissionsDecodingErrors.notANumber }
        self.rawValue = integer
    }
    
    enum PermissionsDecodingErrors: Error {
        case notANumber
    }
    
    public let rawValue: Int64
    
    static var createInstantInvite = Permissions(rawValue: 1 << 0)
    static var kickMembers = Permissions(rawValue: 1 << 1)
    static var banMembers = Permissions(rawValue: 1 << 2)
    static var administrator = Permissions(rawValue: 1 << 3)
    static var manageChannels = Permissions(rawValue: 1 << 4)
    static var manageGuild = Permissions(rawValue: 1 << 5)
    static var addReactions = Permissions(rawValue: 1 << 6)
    static var viewAuditLog = Permissions(rawValue: 1 << 7)
    static var prioritySpeaker = Permissions(rawValue: 1 << 8)
    static var stream = Permissions(rawValue: 1 << 9)
    static var readMessages = Permissions(rawValue: 1 << 10)
    static var sendMessages = Permissions(rawValue: 1 << 11)
    static var sendTTSMessages = Permissions(rawValue: 1 << 12)
    static var manageMessages = Permissions(rawValue: 1 << 13)
    static var embedLinks = Permissions(rawValue: 1 << 14)
    static var attachFiles = Permissions(rawValue: 1 << 15)
    static var readMessageHistory = Permissions(rawValue: 1 << 16)
    static var mentionEveryone = Permissions(rawValue: 1 << 17)
    static var externalEmoji = Permissions(rawValue: 1 << 18)
    static var viewGuildInsights = Permissions(rawValue: 1 << 19)
    static var connectToVoice = Permissions(rawValue: 1 << 20)
    static var speakInVoice = Permissions(rawValue: 1 << 21)
    static var muteMembers = Permissions(rawValue: 1 << 22)
    static var deafenMembers = Permissions(rawValue: 1 << 23)
    static var moveMembers = Permissions(rawValue: 1 << 24)
    static var useVoiceActivation = Permissions(rawValue: 1 << 25)
    static var changeNickname = Permissions(rawValue: 1 << 26)
    static var manageNicknames = Permissions(rawValue: 1 << 27)
    static var manageRoles = Permissions(rawValue: 1 << 28)
    static var manageWebhooks = Permissions(rawValue: 1 << 29)
    static var manageEmoji = Permissions(rawValue: 1 << 30)
    static var useSlashCommands = Permissions(rawValue: 1 << 31)
    static var requestToSpeak = Permissions(rawValue: 1 << 32)
    static var manageEvents = Permissions(rawValue: 1 << 33)
    static var manageThreads = Permissions(rawValue: 1 << 34)
    static var createPublicThreads = Permissions(rawValue: 1 << 35)
    static var createPrivateThreads = Permissions(rawValue: 1 << 36)
    static var externalStickers = Permissions(rawValue: 1 << 37)
    static var sendMessagesInThreads = Permissions(rawValue: 1 << 38)
    static var useEmbeddedActivities = Permissions(rawValue: 1 << 39)
    static var moderateMembers = Permissions(rawValue: 1 << 40)
}

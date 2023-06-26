//
//  Globals.swift
//  Accord
//
//  Created by evelyn on 2022-06-18.
//

import SwiftUI
import Combine

enum GenericErrors: Error {
    case noConnection
    case badGateway
}

enum Storage {
    
    public static var emotes = [String: [DiscordEmote]]()
    
    // these should be merged ideally
    public static var roleColors = [String: (Int, Int)]()
    public static var roleNames = [String: String]()
    
    public static var mergedMembers = [String: Guild.MergedMember]()
    
    public static var users = [String:User]()

    @MainActor
    public static var usernames: [String: String] {
        self.users.mapValues { $0.username }
    }
    
    public static var globals: AppGlobals? = nil
}

final class AppGlobals: ObservableObject {
    
    init() {
        self.connect()
    }
    
    func connect() {
        Storage.globals = self
        self.cancellable = Self.newItemPublisher.sink { [weak self] channel, folder in
            if let channel {
                DispatchQueue.main.async {
                    self?.privateChannels.append(channel)
                    Storage.globals = self
                }
            } else if let folder {
                DispatchQueue.main.async {
                    self?.folders.append(folder)
                    Storage.globals = self
                }
            }
        }
    }
        
    var cancellable: AnyCancellable?
    
    @MainActor @Published
    public var folders = ContiguousArray<GuildFolder>()
    
    @MainActor @Published
    public var privateChannels = [Channel]()
    
    @MainActor @Published
    var selectedChannel: Channel? = nil
    
    @MainActor @Published
    var selectedGuild: Guild? = nil
    
    @MainActor
    var listCache: [String:[OPSItems]] = [:]
    
    @MainActor @Published
    public var discordSettings: DiscordSettings = .init()
    
    @MainActor @Published
    public var userGuildSettings: UserGuildSettings = .init()
    
    @AppStorage("HideMutedChannels")
    var hideMutedChannels: Bool = false
    
    @Published
    public var token: String? = {
        let tokenData = KeychainManager.load(key: keychainItemName)
        if let tokenData, let token = String(data: tokenData, encoding: .utf8), AppGlobals.validateToken(token) {
            return token
        } else {
            return nil
        }
    }()
    
    static func validateToken(_ token: String) -> Bool {
        let components = token.components(separatedBy: ".")
        if let id = components.first,
           let data = id.data(using: .utf8),
           let decoded = Data(base64Encoded: data),
           let result = try? String(decoded),
           Int(result) != nil {
            return true
        } else {
            return false
        }
    }
    
    static var newItemPublisher = PassthroughSubject<(Channel?, GuildFolder?), Never>()
    
    @MainActor
    func permissionsAllowed(_ perms: [Channel.PermissionOverwrites], guildID: String) -> Permissions {
        var permsArray = Permissions(
            folders.lazy
                .map(\.guilds)
                .joined()
                .filter { $0.id == guildID }
                .first?.roles?.lazy
                .compactMap { (role) -> Permissions? in
                    guard Storage.mergedMembers[guildID]?.roles.contains(role.id) == true,
                          let perms = role.permissions,
                          let num = Int64(perms) else { return nil }
                    return Permissions(num)
                } ?? [Permissions]()
        )

        if permsArray.contains(.administrator) {
            permsArray = Permissions.all
            return permsArray
        }

        let everyonePerms = perms.filter { $0.id == guildID }
        permsArray.insert(.init([
            .sendMessages, .readMessages, .changeNickname, .addReactions
        ]))
        permsArray.remove(Permissions(everyonePerms.map(\.deny)))
        permsArray.insert(Permissions(everyonePerms.map(\.allow)))
        let rolePerms = perms.filter { Storage.mergedMembers[guildID]?.roles.contains($0.id) ?? false }
        permsArray.remove(Permissions(rolePerms.map(\.deny)))
        permsArray.insert(Permissions(rolePerms.map(\.allow)))
        let memberPerms = perms.filter { $0.id == Globals.user?.id }
        permsArray.remove(Permissions(memberPerms.map(\.deny)))
        permsArray.insert(Permissions(memberPerms.map(\.allow)))
        return permsArray
    }

}

let smallOperationQueue = DispatchQueue.global(qos: .background)
let userOperationQueue = DispatchQueue.global(qos: .userInteractive)

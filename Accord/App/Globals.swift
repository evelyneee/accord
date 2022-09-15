//
//  Globals.swift
//  Accord
//
//  Created by evelyn on 2022-06-18.
//

import Foundation
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
    
    @MainActor
    public static var users = [String:User]()

    @MainActor
    public static var usernames: [String: String] {
        self.users.mapValues { $0.username }
    }
    
    public static var globals: AppGlobals? = nil
}

@MainActor
final class AppGlobals: ObservableObject {
    
    init() {
        self.connect()
    }
    
    func connect() {
        Storage.globals = self
        self.cancellable = Self.newItemPublisher.sink { [weak self] channel, folder in
            if let channel {
                self?.privateChannels.append(channel)
                Storage.globals = self
            } else if let folder {
                self?.folders.append(folder)
                Storage.globals = self
            }
        }
    }
        
    var cancellable: AnyCancellable?
    
    @MainActor @Published
    public var folders = ContiguousArray<GuildFolder>()
    
    @MainActor @Published
    public var privateChannels = [Channel]()
    
    @MainActor @Published
    var serverListViewSelection: Int? = nil
    
    static var newItemPublisher = PassthroughSubject<(Channel?, GuildFolder?), Never>()
    
    func permissionsAllowed(_ perms: [Channel.PermissionOverwrites], guildID: String) -> Permissions {
        var permsArray = Permissions(
            self.folders.lazy
                .map(\.guilds)
                .joined()
                .filter { $0.id == guildID }
                .first?.roles?.lazy
                .filter { Storage.mergedMembers[guildID]?.roles.contains($0.id) == true }
                .compactMap(\.permissions)
                .compactMap { Int64($0) }
                .map { Permissions($0) } ?? [Permissions]()
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

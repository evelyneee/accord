//
//  Channel+Permissions.swift
//  Accord
//
//  Created by evelyn on 2022-05-18.
//

import Foundation
import CloudKit

extension Array where Self.Element == Channel.PermissionOverwrites {
    func hasPermission(guildID: String, perms: Permissions) -> Bool {
        var allowed = true
        for overwrite in self {
            if (overwrite.id == user_id ||
                ServerListView.mergedMembers[guildID]?.roles.contains(overwrite.id) ?? false) &&
                overwrite.allow.contains(perms) {
                    return true
            }
            if (overwrite.id == user_id ||
                // for the role permissions
               ServerListView.mergedMembers[guildID]?.roles.contains(overwrite.id) ?? false ||
                // for the everyone permissions
                overwrite.id == guildID) &&
                overwrite.deny.contains(perms) {
                    allowed = false
            }
        }
        return allowed
    }
    
    func allAllowed(guildID: String) -> Permissions {
        var permsArray = ServerListView.mergedMembers[guildID]?.cachedPermissions ?? Permissions (
            ServerListView.folders.lazy
                .map { $0.guilds }
                .joined()
                .filter { $0.id == guildID }
                .first?.roles?.lazy
                .filter { ServerListView.mergedMembers[guildID]?.roles.contains($0.id) == true }
                .compactMap { $0.permissions }
                .compactMap { Int64($0) }
                .map { Permissions($0) } ?? [Permissions]()
            )
        
        ServerListView.mergedMembers[guildID]?.cachedPermissions = permsArray
        
        if permsArray.contains(.administrator) {
            permsArray = Permissions(rawValue: 2199023255551)
            return permsArray
        }
        
        let everyonePerms = self.filter { $0.id == guildID }
        permsArray.insert(.init([
            .sendMessages, .readMessages
        ]))
        permsArray.remove(Permissions(everyonePerms.map(\.deny)))
        permsArray.insert(Permissions(everyonePerms.map(\.allow)))
        let rolePerms = self.filter { ServerListView.mergedMembers[guildID]?.roles.contains($0.id) ?? false }
        permsArray.remove(Permissions(rolePerms.map(\.deny)))
        permsArray.insert(Permissions(rolePerms.map(\.allow)))
        let memberPerms = self.filter { $0.id == AccordCoreVars.user?.id }
        permsArray.remove(Permissions(memberPerms.map(\.deny)))
        permsArray.insert(Permissions(memberPerms.map(\.allow)))
        return permsArray
    }
}

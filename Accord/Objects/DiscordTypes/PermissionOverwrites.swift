//
//  Channel+Permissions.swift
//  Accord
//
//  Created by evelyn on 2022-05-18.
//

import CloudKit
import Foundation

extension Array where Self.Element == Channel.PermissionOverwrites {
    func hasPermission(guildID: String, perms: Permissions) -> Bool {
        var allowed = true
        for overwrite in self {
            if overwrite.id == user_id ||
                Storage.mergedMembers[guildID]?.roles.contains(overwrite.id) ?? false,
                overwrite.allow.contains(perms)
            {
                return true
            }
            if overwrite.id == user_id ||
                // for the role permissions
                Storage.mergedMembers[guildID]?.roles.contains(overwrite.id) ?? false ||
                // for the everyone permissions
                overwrite.id == guildID,
                overwrite.deny.contains(perms)
            {
                allowed = false
            }
        }
        return allowed
    }
}

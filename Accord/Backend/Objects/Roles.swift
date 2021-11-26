//
//  Roles.swift
//  Accord
//
//  Created by evelyn on 2021-06-27.
//

import Foundation
import AppKit

final class RoleManager {
    static var shared: RoleManager = RoleManager()
    final func arrangeRoleColors(guilds: [Guild]) -> [String:(Int, Int)] {
        var returnArray: [String:(Int, Int)] = [:]
        for guild in guilds {
            if var roles = guild.roles {
                roles.sort { $0.position > $1.position }
                for role in roles {
                    if !(Array(returnArray.keys).contains(role.id)) {
                        if let color = role.color, role.color != 0 {
                            returnArray[role.id] = (color, role.position)
                        }
                    }
                }
            }
        }
        return returnArray
    }
}

final class Role: Decodable {
    var id: String
    var name: String
    var color: Int?
    var hoist: Bool
    var position: Int
    var permissions: String?
    var managed: Bool
    var mentionable: Bool
}

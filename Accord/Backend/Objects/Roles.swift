//
//  Roles.swift
//  Accord
//
//  Created by evelyn on 2021-06-27.
//

import Foundation

final class RoleManager {
    static var shared: RoleManager? = RoleManager()
    func arrangeRoleColors(guilds: [[String:Any]]) -> [String:Int] {
        var returnArray: [String:Int] = [:]
        for guild in guilds {
            if var roles = (guild["roles"] as? [[String:Any]]) {
                roles.sort { $1["position"] as! Int > $0["position"] as! Int }
                for role in roles {
                    if !(Array(returnArray.keys).contains(role["id"] as! String)) {
                        if role["color"] as! Int != 0 {
                            returnArray[role["id"] as! String] = role["color"] as? Int ?? 0
                        }
                    }
                }
            }
        }
        return returnArray
    }
}

//
//  Guilds.swift
//  Accord
//
//  Created by evelyn on 2021-06-13.
//

import Foundation

enum club {
    case id
    case name
    case members
}

enum channel {
    case id
    case name
}

final class GuildManager {
    static var shared = GuildManager()
    var currentGuild: String = ""
    func calculateDistance(array: [String], one: String, two: String) -> Int {
        if let firstindex = array.firstIndex(where: {$0 == one}),
            let secondIndex = array.firstIndex(where: {$0 == two}) {
            return ((secondIndex - firstindex) + array.count) % array.count
        } else {
            // One or both inputs not part of the array
            return -1
        }
    }
    func channelCount(array: [[String:Any]], index: Int) -> [String:[String]] {
        print(array, "HERE")
        var returnArray: [String:[String]] = [:]
        for channel in array {
            if (channel["type"] as? Int ?? 2) != 4 {
                var currentArray = returnArray[channel["parent_id"] as? String ?? ""]
                if currentArray == nil {
                    currentArray = []
                }
                currentArray?.append(channel["id"] as? String ?? "")
                returnArray[channel["parent_id"] as? String ?? ""] = currentArray
            }
        }
        return returnArray
    }
    func getGuild(clubid: String, array: [[String:Any]], type: club) -> [Any] {
        var _: [Any] = []

        _ = false
        switch type {
        case .id:
            for (_, guild) in array.enumerated() {
                if (guild["id"] as! String) == clubid {
                    let ids = (guild["channels"] as? [[String:Any]] ?? []).compactMap { elem -> Any? in
                        if (elem["type"] as? Int ?? 2) != 4 {
                            return elem["id"]
                        } else {
                            return nil
                        }
                    }
                    return ids as [Any]
                } else {
                }
            }
        case .name:
            for (_, guild) in array.enumerated() {
                if (guild["id"] as! String) == clubid {
                    let names = (guild["channels"] as? [[String:Any]] ?? []).compactMap { elem -> Any? in
                        if (elem["type"] as? Int ?? 2) != 4 {
                            return elem["name"]
                        } else {
                            return nil
                        }
                    }
                    return names as [Any]
                } else {
                }

            }
        case .members:
            for (_, guild) in array.enumerated() {
                let names = (guild["channels"] as? [[String:Any]] ?? []).map { $0["members"] }
                return names as [Any]
            }
        }
        return []
    }
}

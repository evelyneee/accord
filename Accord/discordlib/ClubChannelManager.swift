//
//  ClubChannelManager.swift
//  Helselia
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

final class ClubManager {
    static var shared = ClubManager()
    var currentClub: String = ""
    func getClub(clubid: String, array: [[String:Any]], type: club) -> [Any] {
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

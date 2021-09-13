//
//  MessageGrouping.swift
//  MessageGrouping
//
//  Created by evelyn on 2021-09-08.
//

import Foundation

extension GuildView {
    func fastIndexMessage(_ message: String, array: [Message]) -> Int? {
        let messageDict = array.enumerated().compactMap { (index, element) in
            return [element.id:index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        return messageDict[message]
    }
    func getCachedMemberChunk() {
        let allUserIDs = Array(NSOrderedSet(array: data.map { $0.author?.id ?? "" })) as! Array<String>
        for user in allUserIDs {
            if let person = WebSocketHandler.shared.cachedMemberRequest["\(guildID)$\(user)"] {
                let nickname = person.nick ?? person.user.username
                nicks[(person.user.id)] = nickname
                var rolesTemp: [String] = []
                for _ in 0..<100 {
                    rolesTemp.append("empty")
                }
                for role in (person.roles ?? []) {
                    rolesTemp[roleColors[role]?.1 ?? 0] = role
                }
                rolesTemp = rolesTemp.compactMap { role -> String? in
                    if role == "empty" {
                        return nil
                    } else {
                        return role
                    }
                }
                rolesTemp = rolesTemp.reversed()
                roles[(person.user.id)] = rolesTemp
            }
        }
    }
}

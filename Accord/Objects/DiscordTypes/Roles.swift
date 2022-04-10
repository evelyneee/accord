//
//  Roles.swift
//  Accord
//
//  Created by evelyn on 2021-06-27.
//

import AppKit
import Foundation

final class RoleManager {
    final class func arrangeRoleColors(guilds: [Guild]) -> [String: (Int, Int)] {
        let value: [String: (Int, Int)] = guilds
            .compactMap(\.roles)
            .joined()
            .sorted(by: { $0.position > $1.position })
            .compactMap { role -> [String: (Int, Int)]? in
                guard let color = role.color, color != 0 else { return nil }
                return [role.id: (color, role.position)]
            }
            .reduce(into: [:]) { result, next in
                result.merge(next) { _, rhs in rhs }
            }
        return value
    }
  
  final class func arrangeRoleNames(guilds: [Guild]) -> [String: String] {
      let value: [String: String] = guilds
          .compactMap(\.roles)
          .joined()
          .sorted(by: { $0.position > $1.position })
          .compactMap { role -> [String: String]? in
              return [role.id: role.name]
          }
          .reduce(into: [:]) { result, next in
              result.merge(next) { _, rhs in rhs }
          }
      return value
  }
}

struct Role: Codable {
    var id: String
    var name: String
    var color: Int?
    var position: Int
    var permissions: String?
}

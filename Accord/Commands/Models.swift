//
//  Models.swift
//  Accord
//
//  Created by evelyn on 2022-01-21.
//

import Foundation

final class Command: Codable {}

final class Interaction: Codable {
    var id: String
    var type: Int
    var name: String
    var user: User?
}

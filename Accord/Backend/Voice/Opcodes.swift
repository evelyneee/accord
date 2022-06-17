//
//  Opcodes.swift
//  Accord
//
//  Created by evelyn on 2022-06-02.
//

import Foundation

enum Opcodes: Int {
    case `init` = 0
    case protocolUpdate = 1
    case ready = 2
    case ping = 3
    case codecUpdate = 4
    case status = 5
    case pong = 6
    case hello = 8
    case typeUpdate = 12
    case versionUpdate = 16
}

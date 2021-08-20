//
//  Enums.swift
//  Enums
//
//  Created by evelyn on 2021-08-16.
//

import Foundation

public class requests {
    enum requestTypes {
        case GET
        case POST
        case PATCH
        case DELETE
        case PUT
    }
}

enum statusIndicators {
    case online
    case dnd
    case idle
}

enum Nitro {
    case none
    case classic
    case nitro
}

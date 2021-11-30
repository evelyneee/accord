//
//  MemberList.swift
//  Accord
//
//  Created by evelyn on 2021-11-28.
//

import Foundation

final class MemberListUpdate: Codable {
    var d: MemberList
}

final class MemberList: Codable {
    var ops: [ListOPS]
}

final class ListOPS: Codable {
    var items: [OPSItems]?
}

final class OPSItems: Codable {
    var member: GuildMember?
}

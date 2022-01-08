//
//  MemberList.swift
//  Accord
//
//  Created by evelyn on 2021-11-28.
//

import Foundation

final class MemberListUpdate: Decodable {
    var d: MemberList
}

final class MemberList: Decodable {
    var ops: [ListOPS]
}

final class ListOPS: Decodable {
    var items: [OPSItems]?
}

final class OPSItems: Decodable {
    var member: GuildMember?
}

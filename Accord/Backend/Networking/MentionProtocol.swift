//
//  MentionProtocol.swift
//  MentionProtocol
//
//  Created by evelyn on 2021-09-01.
//

import Foundation

protocol MentionSenderDelegate {
    func addMention(guild: String, channel: String)
}

class MentionSender {
    static let shared = MentionSender()
    public var delegate: MentionSenderDelegate?
    func addMention(guild: String, channel: String) {
        delegate?.addMention(guild: guild, channel: channel)
    }
}

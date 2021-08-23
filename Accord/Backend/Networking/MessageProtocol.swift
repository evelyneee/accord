//
//  MessageProtocol.swift
//  MessageProtocol
//
//  Created by evelyn on 2021-08-21.
//

import Foundation

protocol MessageControllerDelegate {
    func sendMessage(msg: Data, channelID: String?)
    func editMessage(msg: Data, channelID: String?)
    func deleteMessage(msg: Data, channelID: String?)
    func typing(msg: [String: Any], channelID: String?)
    func sendMemberChunk(msg: Data)
    func sendWSError(msg: String)
}

class MessageController {
    static let shared = MessageController()
    public var delegate: MessageControllerDelegate?
    func sendMessage(msg: Data, channelID: String?) {
        delegate?.sendMessage(msg: msg, channelID: channelID)
    }
    func editMessage(msg: Data, channelID: String?) {
        delegate?.editMessage(msg: msg, channelID: channelID)
    }
    func deleteMessage(msg: Data, channelID: String?) {
        delegate?.deleteMessage(msg: msg, channelID: channelID)
    }
    func typing(msg: [String: Any], channelID: String?) {
        delegate?.typing(msg: msg, channelID: channelID)
    }
    func sendMemberChunk(msg: Data) {
        delegate?.sendMemberChunk(msg: msg)
    }
    func sendWSError(msg: String) {
        delegate?.sendWSError(msg: msg)
    }
}

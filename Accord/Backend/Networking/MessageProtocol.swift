//
//  MessageProtocol.swift
//  MessageProtocol
//
//  Created by evelyn on 2021-08-21.
//

import Foundation

protocol MessageControllerDelegate {
    func sendMessage(msg: Data, channelID: String?, isMe: Bool)
    func editMessage(msg: Data, channelID: String?)
    func deleteMessage(msg: Data, channelID: String?)
    func typing(msg: [String: Any], channelID: String?)
    func sendMemberChunk(msg: Data)
    func sendMemberList(msg: MemberListUpdate)
    func sendWSError(msg: String)
}

class MessageController {
    static let shared = MessageController()
    public var delegate: MessageControllerDelegate?
    
    func sendMessage(msg: Data, channelID: String?, isMe: Bool = false) {
        delegate?.sendMessage(msg: msg, channelID: channelID, isMe: isMe)
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
    func sendMemberList(msg: MemberListUpdate) {
        delegate?.sendMemberList(msg: msg)
    }
    func sendWSError(msg: String) {
        delegate?.sendWSError(msg: msg)
    }
}

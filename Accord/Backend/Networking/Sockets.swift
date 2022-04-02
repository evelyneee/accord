//
//  Sockets.swift
//  Accord
//
//  Created by evelyn on 2021-06-05.
//

import Combine
import Foundation

final class Notifications {
    static var shared = Notifications()
    final var notifications: [(String, String)] = [] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "Notification"), object: nil, userInfo: ["info": (self.notifications.first) ?? [:]])
            }
        }
    }

    final var privateChannels: [String] = []
    final func clearNotifications(forSet: (String, String)) {
        for (i, notif) in notifications.enumerated() {
            if notif == forSet {
                notifications.remove(at: i)
            }
        }
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String { get }
}

final class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    static var shared = WebSocketDelegate()
    var connected = false
    func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didOpenWithProtocol _: String?) {
        releaseModePrint("[Accord] Web Socket did connect")
        connected = true
    }

    func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        connected = false
        releaseModePrint("[Accord] Web Socket did disconnect")
        let reason = String(decoding: reason ?? Data(), as: UTF8.self)
        MessageController.shared.sendWSError(msg: reason)
        print("[Accord] Error from Discord: \(reason)")

        // MARK: WebSocket close codes.

        switch closeCode {
        case .invalid:
            releaseModePrint("Socket closed because payload was invalid")
        case .normalClosure:
            releaseModePrint("[Accord] Socket closed because connection was closed")
            releaseModePrint(reason)
        case .goingAway:
            releaseModePrint("[Accord] Socket closed because connection was closed")
            releaseModePrint(reason)
        case .protocolError:
            releaseModePrint("[Accord] Socket closed because there was a protocol error")
        case .unsupportedData:
            releaseModePrint("[Accord] Socket closed input/output data was unsupported")
        case .noStatusReceived:
            releaseModePrint("[Accord] Socket closed no status was received")
        case .abnormalClosure:
            releaseModePrint("[Accord] Socket closed, there was an abnormal closure")
        case .invalidFramePayloadData:
            releaseModePrint("[Accord] Socket closed the frame data was invalid")
        case .policyViolation:
            releaseModePrint("[Accord] Socket closed: Policy violation")
        case .messageTooBig:
            releaseModePrint("[Accord] Socket closed because the message was too big")
        case .mandatoryExtensionMissing:
            releaseModePrint("[Accord] Socket closed because an extension was missing")
        case .internalServerError:
            releaseModePrint("Socket closed because there was an internal server error")
        case .tlsHandshakeFailure:
            releaseModePrint("[Accord] Socket closed because the tls handshake failed")
        @unknown default:
            releaseModePrint("[Accord] Socket closed for unknown reason")
        }
        #if DEBUG
            // fatalError("Socket Disconnected: \(reason) \(closeCode)")
        #endif
    }
}

final class WebSocket {
    var ws: URLSessionWebSocketTask!
    let session: URLSession
    let webSocketDelegate = WebSocketDelegate.shared
    var session_id: String?
    var seq: Int?
    var heartbeat_interval: Int?
    var cachedMemberRequest: [String: GuildMember] = [:]
    typealias completionBlock = (_ value: GatewayD?) -> Void

    // MARK: - init

    init(url: URL?) {
        releaseModePrint("[Accord] [Socket] Hello world!")

        var config = URLSessionConfiguration.default

        if proxyEnabled {
            config = config.setProxy()
        }
        session = URLSession(configuration: config, delegate: webSocketDelegate, delegateQueue: nil)
        ws = session.webSocketTask(with: url!)
        ws.maximumMessageSize = 9_999_999_999
        ws.resume()
        initialReception()
        ping()
        authenticate()
        releaseModePrint("[Accord] Socket initiated")
    }

    // MARK: - Ping

    func ping() {
        ws.sendPing { error in
            if let error = error {
                releaseModePrint("[Accord] Error when sending PING \(error)")
            } else {
                print("[Accord] Web Socket connection is alive")
            }
        }
    }

    // MARK: Decode payloads

    func decodePayload(payload: Data) -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any]
    }

    // MARK: Initial WS setup

    func initialReception() {
        ws.receive { [weak self] result in
            switch result {
            case let .success(message):
                switch message {
                case .data:
                    break
                case let .string(text):
                    if let data = text.data(using: String.Encoding.utf8) {
                        let hello = self?.decodePayload(payload: data) ?? [:]
                        self?.heartbeat_interval = (hello["d"] as? [String: Any] ?? [:])["heartbeat_interval"] as? Int ?? 0
                        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(self?.heartbeat_interval ?? 0)) {
                            self?.heartbeat()
                        }
                    }
                @unknown default:
                    print("[Accord] unknown")
                }
            case let .failure(error):
                print("[Accord] Error when init receiving \(error)")
            }
        }
    }

    // MARK: - Ready

    func ready(_ completion: @escaping completionBlock) {
        ws.receive { result in
            switch result {
            case let .success(message):
                switch message {
                case .data:
                    break
                case let .string(text):
                    if let data = text.data(using: String.Encoding.utf8) {
                        let path = FileManager.default.urls(for: .cachesDirectory,
                                                            in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                        releaseModePrint(path)
                        try! data.write(to: path)
                        guard let structure = try? JSONDecoder().decode(GatewayStructure.self, from: data) else {
                            return completion(nil)
                        }
                        wssThread.async {
                            self.receive()
                        }
                        return completion(structure.d)
                    }
                @unknown default:
                    print("[Accord] unknown")
                }
            case let .failure(error):
                print("[Accord] Error when init receiving \(error)")
            }
        }
    }

    // MARK: ACK

    func heartbeat() {
        let packet: [String: Any] = [
            "op": 1,
            "d": seq ?? 0,
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            ws.send(.string(jsonString)) { [weak self] error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                    print("[Accord] RECONNECT")
                    self?.ws.resume()
                    self?.reconnect()
                }
                print("[Accord] heartbeat")
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(self?.heartbeat_interval ?? 0)) {
                    self?.heartbeat()
                }
            }
        }
    }

    // MARK: Authentication

    func authenticate() {
        let packet: [String: Any] = [
            "op": 2,
            "d": [
                "token": AccordCoreVars.shared.token,
                "capabilities": 125,
                "compress": false,
                "properties": [
                    "os": "Mac OS X",
                    "browser": "Discord Client",
                    "release_channel": "canary",
                    "client_build_number": 101_473,
                    "client_version": "0.0.278",
                    "os_version": "21.1.0",
                    "os_arch": "x64",
                    "system-locale": "en-US",
                ],
            ],
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                    print("[Accord] RECONNECT")
                }
            }
        }
    }

    final func close() {
        let reason = "Closing connection".data(using: .utf8)
        ws.cancel(with: .goingAway, reason: reason)
    }

    final func reconnect() {
        let packet: [String: Any] = [
            "op": 6,
            "d": [
                "seq": Int(seq ?? 0),
                "session_id": String(session_id ?? ""),
                "token": AccordCoreVars.shared.token,
            ],
        ]
        print("RECONNECT SENDING", packet)
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending reconnect error: \(error)")
                }
            }
        }
    }

    final func subscribe(_ guild: String, _: String) {
        let packet: [String: Any] = [
            "op": 14,
            "d": [
                "guild_id": guild,
                "typing": true,
                "activities": true,
                "threads": false,
                "members": [],
            ],
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }

    final func subscribeToDM(_ channel: String) {
        let packet: [String: Any] = [
            "op": 13,
            "d": [
                "channel_id": channel,
            ],
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }

    final func getMembers(ids: [String], guild: String) {
        let packet: [String: Any] = [
            "op": 8,
            "d": [
                "limit": 0,
                "user_ids": ids,
                "guild_id": guild,
            ],
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }

    final func frame() {
        ws.receive { result in
            switch result {
            case let .success(message):
                switch message {
                case let .string(text):
                    if let data = text.data(using: .utf8) {
                        guard let payload = self.decodePayload(payload: data), let op = payload["op"] as? Int else { return }
                        guard let s = payload["s"] as? Int else {
                            if op == 11 {
                                // no seq + op 11 means a hearbeat was done successfully
                                print("[Accord] Heartbeat successful")
                                self.frame()
                            } else {
                                // disconnected?
                                self.reconnect()
                            }
                            return
                        }
                        self.seq = s
                        guard let t = payload["t"] as? String else {
                            self.frame()
                            return
                        }
                        switch t {
                        case "READY":
                            let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                            try? data.write(to: path)
                            guard let structure = try? JSONDecoder().decode(GatewayStructure.self, from: data) else { break }
                            releaseModePrint("[Accord] Gateway ready (\(structure.d.v ?? 0), \(structure.d.user.username)#\(structure.d.user.discriminator))")
                            self.session_id = structure.d.session_id

                        // MARK: Channel Event Handlers

                        case "CHANNEL_CREATE": break
                        case "CHANNEL_UPDATE": break
                        case "CHANNEL_DELETE": break

                        // MARK: Guild Event Handlers

                        case "GUILD_CREATE": print("[Accord] something was created")
                        case "GUILD_DELETE": break
                        case "GUILD_MEMBER_ADD": break
                        case "GUILD_MEMBER_REMOVE": break
                        case "GUILD_MEMBER_UPDATE": break
                        case "GUILD_MEMBERS_CHUNK":
                            MessageController.shared.sendMemberChunk(msg: data)

                        // MARK: Invite Event Handlers

                        case "INVITE_CREATE": break
                        case "INVITE_DELETE": break

                        // MARK: Message Event Handlers

                        case "MESSAGE_CREATE":
                            guard let dict = payload["d"] as? [String: Any] else { break }
                            if let channelID = dict["channel_id"] as? String, let author = dict["author"] as? [String: Any], let id = author["id"] as? String, id == user_id {
                                MessageController.shared.sendMessage(msg: data, channelID: channelID, isMe: true)
                            } else if let channelID = dict["channel_id"] as? String {
                                MessageController.shared.sendMessage(msg: data, channelID: channelID)
                            }
                            if (((payload["d"] as! [String: Any])["mentions"] as? [[String: Any]] ?? []).map { $0["id"] as? String ?? "" }).contains(user_id) {
                                showNotification(title: ((payload["d"] as! [String: Any])["author"] as! [String: Any])["username"] as? String ?? "", subtitle: (payload["d"] as! [String: Any])["content"] as! String)
                                MentionSender.shared.addMention(guild: dict["guild_id"] as? String ?? "@me", channel: dict["channel_id"] as! String)
                            } else if Notifications.shared.privateChannels.contains(dict["channel_id"] as! String), (((payload["d"] as! [String: Any])["author"] as! [String: Any])["id"] as? String ?? "") != user_id {
                                showNotification(title: ((payload["d"] as! [String: Any])["author"] as! [String: Any])["username"] as? String ?? "", subtitle: (payload["d"] as! [String: Any])["content"] as! String)
                                MentionSender.shared.addMention(guild: "@me", channel: dict["channel_id"] as! String)
                            }
                        case "MESSAGE_UPDATE":
                            let dict = payload["d"] as! [String: Any]
                            if let channelid = dict["channel_id"] as? String {
                                MessageController.shared.editMessage(msg: data, channelID: channelid)
                            }
                        case "MESSAGE_DELETE":
                            let dict = payload["d"] as! [String: Any]
                            if let channelid = dict["channel_id"] as? String {
                                MessageController.shared.deleteMessage(msg: data, channelID: channelid)
                            }
                        case "MESSAGE_REACTION_ADD": print("[Accord] something was created")
                        case "MESSAGE_REACTION_REMOVE": print("[Accord] something was created")
                        case "MESSAGE_REACTION_REMOVE_ALL": print("[Accord] something was created")
                        case "MESSAGE_REACTION_REMOVE_EMOJI": print("[Accord] something was created")

                        // MARK: Presence Event Handlers

                        case "PRESENCE_UPDATE": break
                        case "TYPING_START":
                            print("typing")
                            let data = payload["d"] as! [String: Any]
                            print(data)
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.typing(msg: data, channelID: channelid)
                            }
                        case "USER_UPDATE": break
                        default: break
                        }
                    }
                case .data: break
                default: break
                }
            case let .failure(error):
                releaseModePrint(error.localizedDescription)
            }
        }
    }

    // MARK: - Receive

    final func receive() {
        ws.receive { [weak self] result in
            switch result {
            case let .success(message):
                switch message {
                case let .string(text):
                    if let textData = text.data(using: String.Encoding.utf8) {
                        let payload = self?.decodePayload(payload: textData) ?? [:]
                        if payload["s"] as? Int != nil {
                            self?.seq = payload["s"] as? Int
                        } else {
                            if (payload["op"] as? Int ?? 0) != 11 {
                                self?.reconnect()
                            } else {
                                print("[Accord] Heartbeat successful")
                            }
                        }
                        switch payload["t"] as? String ?? "" {
                        case "READY":
                            let path = FileManager.default.urls(for: .cachesDirectory,
                                                                in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                            try! textData.write(to: path)
                            guard let structure = try? JSONDecoder().decode(GatewayStructure.self, from: textData) else { break }
                            releaseModePrint("[Accord] Gateway ready (\(structure.d.v ?? 0), \(structure.d.user.username)#\(structure.d.user.discriminator))")
                            self?.session_id = structure.d.session_id

                        // MARK: Channel Event Handlers

                        case "CHANNEL_CREATE": break
                        case "CHANNEL_UPDATE": break
                        case "CHANNEL_DELETE": break

                        // MARK: Guild Event Handlers

                        case "GUILD_CREATE": print("[Accord] something was created")
                        case "GUILD_DELETE": break
                        case "GUILD_MEMBER_ADD": break
                        case "GUILD_MEMBER_REMOVE": break
                        case "GUILD_MEMBER_UPDATE": break
                        case "GUILD_MEMBERS_CHUNK":
                            DispatchQueue.main.async {
                                MessageController.shared.sendMemberChunk(msg: textData)
                            }

                        // MARK: Invite Event Handlers

                        case "INVITE_CREATE": break
                        case "INVITE_DELETE": break

                        // MARK: Message Event Handlers

                        case "MESSAGE_CREATE":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.sendMessage(msg: textData, channelID: channelid)
                            }
                            if (((payload["d"] as! [String: Any])["mentions"] as? [[String: Any]] ?? []).map { $0["id"] as? String ?? "" }).contains(user_id) {
                                print("[Accord] NOTIFICATION SENDING NOW")
                                showNotification(title: ((payload["d"] as! [String: Any])["author"] as! [String: Any])["username"] as? String ?? "", subtitle: (payload["d"] as! [String: Any])["content"] as! String)
                                MentionSender.shared.addMention(guild: data["guild_id"] as? String ?? "@me", channel: data["channel_id"] as! String)
                            } else if Notifications.shared.privateChannels.contains(data["channel_id"] as! String), (((payload["d"] as! [String: Any])["author"] as! [String: Any])["id"] as? String ?? "") != user_id {
                                print("[Accord] NOTIFICATION SENDING NOW")
                                showNotification(title: ((payload["d"] as! [String: Any])["author"] as! [String: Any])["username"] as? String ?? "", subtitle: (payload["d"] as! [String: Any])["content"] as! String)
                                MentionSender.shared.addMention(guild: "@me", channel: data["channel_id"] as! String)
                            }
                        case "MESSAGE_UPDATE":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.editMessage(msg: textData, channelID: channelid)
                            }
                        case "MESSAGE_DELETE":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.deleteMessage(msg: textData, channelID: channelid)
                            }
                        case "MESSAGE_REACTION_ADD": print("[Accord] something was created")
                        case "MESSAGE_REACTION_REMOVE": print("[Accord] something was created")
                        case "MESSAGE_REACTION_REMOVE_ALL": print("[Accord] something was created")
                        case "MESSAGE_REACTION_REMOVE_EMOJI": print("[Accord] something was created")

                        // MARK: Presence Event Handlers

                        case "PRESENCE_UPDATE": break
                        case "TYPING_START":
                            print("typing")
                            let data = payload["d"] as! [String: Any]
                            print(data)
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.typing(msg: data, channelID: channelid)
                            }
                        case "USER_UPDATE": break
                        default: break
                        }
                    }
                    self?.receive() // call back the function, creating a loop
                case .data: break
                @unknown default: break
                }
            case let .failure(error):
                releaseModePrint("[Accord] Error when receiving loop \(error)")
                print("[Accord] RECONNECT")
            }
        }
    }
}

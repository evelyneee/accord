//
//  Sockets.swift
//  Accord
//
//  Created by evelyn on 2021-06-05.
//

import Foundation
import Combine

final class Notifications {
    static var shared = Notifications()
    final var notifications: [(String, String)] = [] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "Notification"), object: nil, userInfo: ["info":(self.notifications.first) ?? [:]])
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
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        releaseModePrint("[Accord] Web Socket did connect")
        connected = true
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
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
        fatalError("Socket Disconnected: \(reason) \(closeCode)")
        #endif
    }
}


final class WebSocket {
    
    var ws: URLSessionWebSocketTask!
    let session: URLSession
    let webSocketDelegate = WebSocketDelegate.shared
    var session_id: String? = nil
    var seq: Int? = nil
    var heartbeat_interval: Int? = nil
    var cachedMemberRequest: [String:GuildMember] = [:]
    typealias completionBlock = ((_ value: Optional<GatewayD>) -> Void)
    
    // MARK: - init
    init(url: URL?) {
        var config = URLSessionConfiguration.default
        
        if proxyEnabled {
            config = config.setProxy()
        }
        session = URLSession(configuration: config, delegate: webSocketDelegate, delegateQueue: nil)
        ws = session.webSocketTask(with: url!)
        ws.maximumMessageSize = 9999999999
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
    func decodePayload(payload: Data) -> [String: Any] {
        do {
            return try JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any] ?? [:]
        } catch {
            return [:]
        }
    }

    // MARK: Initial WS setup
    func initialReception() {
        ws.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    break
                case .string(let text):
                    if let data = text.data(using: String.Encoding.utf8) {
                        let hello = self?.decodePayload(payload: data) ?? [:]
                        self?.heartbeat_interval = (hello["d"] as? [String:Any] ?? [:])["heartbeat_interval"] as? Int ?? 0
                        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(self?.heartbeat_interval ?? 0), execute: {
                            self?.heartbeat()
                        })

                    }
                @unknown default:
                    print("[Accord] unknown")
                    break
                }
            case .failure(let error):
                print("[Accord] Error when init receiving \(error)")
            }
        }
    }

    // MARK: - Ready
    func ready(_ completion: @escaping completionBlock) {
        ws.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    break
                case .string(let text):
                    if let data = text.data(using: String.Encoding.utf8) {
                        guard let structure = try? JSONDecoder().decode(GatewayStructure.self, from: data) else {
                            return completion(nil)
                        }
                        self.receive()
                        return completion(structure.d)
                    }
                @unknown default:
                    print("[Accord] unknown")
                    break
                }
            case .failure(let error):
                print("[Accord] Error when init receiving \(error)")
            }
        }
    }

    
    // MARK: ACK
    func heartbeat() {
        let packet: [String:Any] = [
            "op":1,
            "d":self.seq ?? 0
        ]
        socketEvents.append(["heartbeat (op 9) ~>":String(describing: packet as [String:Any])])
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { [weak self] error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                    print("[Accord] RECONNECT")
                    self?.ws.resume()
                    self?.reconnect()
                }
                print("[Accord] heartbeat")
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(self?.heartbeat_interval ?? 0), execute: {
                    self?.heartbeat()
                })
            }
        }
    }

    // MARK: Authentication
    func authenticate() {
        let packet: [String:Any] = [
            "op":2,
            "d":[
                "token":AccordCoreVars.shared.token,
                "capabilities":125,
                "compress":false,
                "properties": [
                    "os":"Mac OS X",
                    "browser":"Discord Client",
                    "release_channel":"canary",
                    "client_build_number": 101473,
                    "client_version":"0.0.278",
                    "os_version":"21.1.0",
                    "os_arch":"x64",
                    "system-locale":"en-US",
                ]
            ]
        ]
        socketEvents.append(["identify (op 2) ~>":String(describing: packet as [String:Any])])
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
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
        let packet: [String:Any] = [
            "op":6,
            "d":[
                "token":AccordCoreVars.shared.token,
                "session_id":String(self.session_id ?? ""),
                "seq":Int(self.seq ?? 0)
            ]
        ]
        print("RECONNECT SENDING", packet)
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending reconnect error: \(error)")
                }
                return
            }
        }
    }
    final func subscribe(_ guild: String, _ channel: String) {
        let packet: [String:Any] = [
            "op":14,
            "d": [
                "guild_id":guild,
                "typing":true,
                "activities":true,
                "threads":false,
                "members":[]
            ],
        ]
        socketEvents.append(["subscribe to channel (op 14) ~>":String(describing: packet as [String:Any])])
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }
    final func subscribeToDM(_ channel: String) {
        let packet: [String:Any] = [
            "op":13,
            "d": [
                "channel_id":channel
            ],
        ]
        socketEvents.append(["subscribe to dm (op 13) ~>":String(describing: packet as [String:Any])])
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }
    
    func getMembers(ids: [String], guild: String) {
        let packet: [String:Any] = [
            "op":8,
            "d": [
                "limit":0,
                "user_ids":ids,
                "guild_id":guild
            ]
        ]
        socketEvents.append(["get members (op 8) ~>":String(describing: packet as [String:Any])])
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Receive
    func receive() {
        ws.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("[Accord] Data received \(data)")
                case .string(let text):
                    if let textData = text.data(using: String.Encoding.utf8) {
                        let payload = self?.decodePayload(payload: textData) ?? [:]
                        if payload["s"] as? Int != nil {
                            self?.seq = payload["s"] as? Int
                        } else {
                            if (payload["op"] as? Int ?? 0) != 11 {
                                print("[Accord] RECONNECT")
                                self?.reconnect()
                                sleep(2)
                            } else {
                                print("[Accord] Heartbeat successful")
                            }
                        }
                        socketEvents.append(["\(payload["t"] as? String ?? "") <~":String(describing: payload["d"])])
                        switch payload["t"] as? String ?? "" {
                        case "READY":
                            let path = FileManager.default.urls(for: .cachesDirectory,
                                                                in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                            try! textData.write(to: path)
                            guard let structure = try? JSONDecoder().decode(GatewayStructure.self, from: textData) else { break }
                            releaseModePrint("[Accord] Gateway ready (\(structure.d.v ?? 0), \(structure.d.user.username)#\(structure.d.user.discriminator))")
                            self?.session_id = structure.d.session_id
                            break

                        // MARK: Channel Event Handlers
                        case "CHANNEL_CREATE": break
                        case "CHANNEL_UPDATE": break
                        case "CHANNEL_DELETE": break

                        // MARK: Guild Event Handlers
                        case "GUILD_CREATE": print("[Accord] something was created"); break
                        case "GUILD_DELETE": break
                        case "GUILD_MEMBER_ADD": break
                        case "GUILD_MEMBER_REMOVE": break
                        case "GUILD_MEMBER_UPDATE": break
                        case "GUILD_MEMBERS_CHUNK":
                            DispatchQueue.main.async {
                                MessageController.shared.sendMemberChunk(msg: textData)
                            }
                            break

                        // MARK: Invite Event Handlers
                        case "INVITE_CREATE": break
                        case "INVITE_DELETE": break

                        // MARK: Message Event Handlers
                        case "MESSAGE_CREATE":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.sendMessage(msg: textData, channelID: channelid)
                            }
                            if (((payload["d"] as! [String: Any])["mentions"] as? [[String:Any]] ?? []).map { $0["id"] as? String ?? ""}).contains(user_id) {
                                print("[Accord] NOTIFICATION SENDING NOW")
                                showNotification(title: (((payload["d"] as! [String: Any])["author"]) as! [String:Any])["username"] as? String ?? "", subtitle: (payload["d"] as! [String: Any])["content"] as! String)
                                MentionSender.shared.addMention(guild: data["guild_id"] as? String ?? "@me", channel: data["channel_id"] as! String)
                            } else if Notifications.shared.privateChannels.contains(data["channel_id"] as! String) && ((((payload["d"] as! [String: Any])["author"]) as! [String:Any])["id"] as? String ?? "") != user_id {
                                print("[Accord] NOTIFICATION SENDING NOW")
                                showNotification(title: (((payload["d"] as! [String: Any])["author"]) as! [String:Any])["username"] as? String ?? "", subtitle: (payload["d"] as! [String: Any])["content"] as! String)
                                MentionSender.shared.addMention(guild: "@me", channel: data["channel_id"] as! String)
                            }
                            break
                        case "MESSAGE_UPDATE":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.editMessage(msg: textData, channelID: channelid)
                            }
                            break
                        case "MESSAGE_DELETE":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.deleteMessage(msg: textData, channelID: channelid)
                            }
                            break
                        case "MESSAGE_REACTION_ADD": print("[Accord] something was created"); break
                        case "MESSAGE_REACTION_REMOVE": print("[Accord] something was created"); break
                        case "MESSAGE_REACTION_REMOVE_ALL": print("[Accord] something was created"); break
                        case "MESSAGE_REACTION_REMOVE_EMOJI": print("[Accord] something was created"); break

                        // MARK: Presence Event Handlers
                        case "PRESENCE_UPDATE": break
                        case "TYPING_START":
                            print("typing")
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.typing(msg: data, channelID: channelid)
                            }
                            break
                        case "USER_UPDATE": break
                        default: break
                        }
                    }
                    self?.receive() // call back the function, creating a loop
                @unknown default:
                    print("[Accord] unknown")
                }
            case .failure(let error):
                releaseModePrint("[Accord] Error when receiving loop \(error)")
                print("[Accord] RECONNECT")
            }
        }
    }
}

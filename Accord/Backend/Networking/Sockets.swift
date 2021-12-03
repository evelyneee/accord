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
        releaseModePrint("Web Socket did connect")
        connected = true
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        connected = false
        releaseModePrint("Web Socket did disconnect")
        let reason = String(decoding: reason ?? Data(), as: UTF8.self)
        MessageController.shared.sendWSError(msg: reason)
        print("Error from Discord: \(reason)")
        if reason.contains("auth") {
            _ = KeychainManager.save(key: "me.evelyn.accord.token", data: Data())
        }
        // MARK: WebSocket close codes.
        switch closeCode {
        case .invalid:
            releaseModePrint("Socket closed because payload was invalid")
        case .normalClosure:
            releaseModePrint("Socket closed because connection was closed")
            releaseModePrint(reason)
        case .goingAway:
            releaseModePrint("Socket closed because connection was closed")
            releaseModePrint(reason)
        case .protocolError:
            releaseModePrint(" Socket closed because there was a protocol error")
        case .unsupportedData:
            releaseModePrint("Socket closed input/output data was unsupported")
        case .noStatusReceived:
            releaseModePrint("Socket closed no status was received")
        case .abnormalClosure:
            releaseModePrint("Socket closed, there was an abnormal closure")
        case .invalidFramePayloadData:
            releaseModePrint("Socket closed the frame data was invalid")
        case .policyViolation:
            releaseModePrint("Socket closed: Policy violation")
        case .messageTooBig:
            releaseModePrint("Socket closed because the message was too big")
        case .mandatoryExtensionMissing:
            releaseModePrint("Socket closed because an extension was missing")
        case .internalServerError:
            releaseModePrint("Socket closed because there was an internal server error")
        case .tlsHandshakeFailure:
            releaseModePrint("Socket closed because the tls handshake failed")
        @unknown default:
            releaseModePrint("Socket closed for unknown reason")
        }
    }
}


final class WebSocket {
    
    var ws: URLSessionWebSocketTask!
    let session: URLSession
    let webSocketDelegate = WebSocketDelegate.shared
    var session_id: String? = nil
    var seq: Int? = nil
    var heartbeat_interval: Int = 0
    var cachedMemberRequest: [String:GuildMember] = [:]
    typealias completionBlock = ((_ value: Optional<GatewayD>) -> Void)
    
    // MARK: - init
    init(url: URL?) {
        
        releaseModePrint("[Socket] Hello world!")

        let config = URLSessionConfiguration.default
        
        if proxyEnabled {
            config.setProxy()
        }
        session = URLSession(configuration: config, delegate: webSocketDelegate, delegateQueue: nil)
        ws = session.webSocketTask(with: url!)
        ws.maximumMessageSize = 9999999999
        ws.resume()
        self.hello()
        self.authenticate()
        releaseModePrint("Socket initiated")
    }
    
    func reset() {
        ws.cancel()
        concurrentQueue.asyncAfter(deadline: .now() + 5, execute: {
            wss = WebSocket.init(url: URL(string: "wss://gateway.discord.gg?v=9&encoding=json")!)
        })
        wss = nil
    }
    
    // MARK: - Ping
    func ping() {
        ws.sendPing { error in
            if let error = error {
                releaseModePrint(" Error when sending PING \(error)")
            } else {
                print("Web Socket connection is alive")
            }
        }
    }
    
    // MARK: Decode payloads
    func decodePayload(payload: Data) -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: payload, options: []) as? [String:Any]
    }

    // MARK: Initial WS setup
    func hello() {
        ws.receive { [weak self, ws] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    break
                case .string(let text):
                    if let data = text.data(using: String.Encoding.utf8) {
                        guard let hello = self?.decodePayload(payload: data) else { ws?.cancel(); return }
                        guard let hello = hello["d"] as? [String:Any] else { ws?.cancel(); return }
                        guard let heartbeat_interval = hello["heartbeat_interval"] as? Int else { ws?.cancel(); return }
                        self?.heartbeat_interval = heartbeat_interval
                        wssThread.asyncAfter(deadline: .now() + .milliseconds(heartbeat_interval), execute: {
                            self?.heartbeat()
                        })

                    }
                @unknown default:
                    print("unknown")
                    break
                }
            case .failure(let error):
                print("Error when init receiving \(error)")
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
                        do {
                            let structure = try JSONDecoder().decode(GatewayStructure.self, from: data)
                            wssThread.async {
                                self.receive()
                            }
                            releaseModePrint("Gateway Ready \(structure.d.user.username)#\(structure.d.user.discriminator)")
                            let guildOrder = structure.d.user_settings?.guild_positions ?? []
                            var guildTemp = [Guild]()
                            for item in guildOrder {
                                if let first = ServerListView.fastIndexGuild(item, array: structure.d.guilds) {
                                    guildTemp.append(structure.d.guilds[first])
                                }
                            }
                            structure.d.guilds = guildTemp
                            completion(structure.d)
                            let data = try JSONEncoder().encode(structure)
                            let path = FileManager.default.urls(for: .cachesDirectory,
                                                                in: .userDomainMask)[0]
                                                                .appendingPathComponent("socketOut.json")
                            try data.write(to: path)
                            return
                        } catch {
                            releaseModePrint(error)
                            return completion(nil)
                        }
                    }
                @unknown default:
                    print("unknown")
                    break
                }
            case .failure(let error):
                print("Error when init receiving \(error)")
            }
        }
    }

    
    // MARK: ACK
    func heartbeat() {
        guard let seq = seq else {
            self.reset()
            return
        }
        let packet: [String:Any] = [
            "op":1,
            "d":seq
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let _ = error {
                    self.reconnect()
                }
                wssThread.asyncAfter(deadline: .now() + .milliseconds(self.heartbeat_interval), execute: {
                    self.heartbeat()
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
                    "release_channel":"stable",
                    "client_build_number": 105608,
                    "client_version":"0.0.264",
                    "os_version":"21.1.0",
                    "os_arch":"x64",
                    "system-locale":"en-US",
                ]
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("WebSocket sending error: \(error)")
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
                "seq":Int(self.seq ?? 0),
                "session_id":String(self.session_id ?? ""),
                "token":AccordCoreVars.shared.token
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint(" WebSocket sending reconnect error: \(error)")
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
                "members":[],
//                "channels": [
//                     channel: [["0", "99"]]
//                 ],
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint(" WebSocket sending error: \(error)")
                }
            }
        }
    }
    
    final func subscribeToDM(_ channel: String) {
        let packet: [String:Any] = [
            "op":13,
            "d": [
                "channel_id":channel
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint(" WebSocket sending error: \(error)")
                }
            }
        }
    }
    
    final func getMembers(ids: [String], guild: String) {
        let packet: [String:Any] = [
            "op":8,
            "d": [
                "limit":0,
                "user_ids":ids,
                "guild_id":guild
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint(" WebSocket sending error: \(error)")
                }
            }
        }
    }
        
    // MARK: - Receive
    final func receive() {
        ws.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let textData = text.data(using: .utf8) {
                        guard let payload = self?.decodePayload(payload: textData), let op = payload["op"] as? Int else { return }
                        guard let s = payload["s"] as? Int else {
                            if op == 11 {
                                // no seq + op 11 means a hearbeat was done successfully
                                print("Heartbeat successful")
                                self?.receive()
                            } else {
                                // disconnected?
                                self?.reconnect()
                            }
                            return
                        }
                        self?.seq = s
                        guard let t = payload["t"] as? String else {
                            self?.receive()
                            return
                        }
                        print("new event: ", t)
                        switch t {
                        case "READY":
                            let path = FileManager.default.urls(for: .cachesDirectory,
                                                                in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                            try? textData.write(to: path)
                            guard let structure = try? JSONDecoder().decode(GatewayStructure.self, from: textData) else { break }
                            releaseModePrint(" Gateway ready (\(structure.d.v ?? 0), \(structure.d.user.username)#\(structure.d.user.discriminator))")
                            self?.session_id = structure.d.session_id
                            break

                        // MARK: Channel Event Handlers
                        case "CHANNEL_CREATE": break
                        case "CHANNEL_UPDATE": break
                        case "CHANNEL_DELETE": break

                        // MARK: Guild Event Handlers
                        case "GUILD_CREATE": print("something was created"); break
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
                            guard let dict = payload["d"] as? [String: Any] else { break }
                            if let channelID = dict["channel_id"] as? String, let author = dict["author"] as? [String:Any], let id = author["id"] as? String, id == user_id {
                                MessageController.shared.sendMessage(msg: textData, channelID: channelID, isMe: true)
                            } else if let channelID = dict["channel_id"] as? String {
                                MessageController.shared.sendMessage(msg: textData, channelID: channelID)
                            }
                            guard let mentions = dict["mentions"] as? [[String:Any]] else { break }
                            let ids = mentions.compactMap { $0["id"] as? String }
                            let guild_id = dict["guild_id"] as? String ?? "@me"
                            guard let channel_id = dict["channel_id"] as? String else { break }
                            guard let author = dict["author"] as? [String:Any] else { break }
                            guard let username = author["username"] as? String else { break }
                            guard let user_id = author["id"] as? String else { break }
                            guard let content = dict["content"] as? String else { break }
                            if ids.contains(user_id) {
                                showNotification(title: username, subtitle: content)
                                MentionSender.shared.addMention(guild: guild_id, channel: channel_id)
                            } else if Notifications.shared.privateChannels.contains(channel_id) && user_id != user_id {
                                showNotification(title: username, subtitle: content)
                                MentionSender.shared.addMention(guild: guild_id, channel: channel_id)
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
                        case "MESSAGE_REACTION_ADD": print("something was created"); break
                        case "MESSAGE_REACTION_REMOVE": print("something was created"); break
                        case "MESSAGE_REACTION_REMOVE_ALL": print("something was created"); break
                        case "MESSAGE_REACTION_REMOVE_EMOJI": print("something was created"); break

                        // MARK: Presence Event Handlers
                        case "PRESENCE_UPDATE": break
                        case "TYPING_START":
                            let data = payload["d"] as! [String: Any]
                            if let channelid = data["channel_id"] as? String {
                                MessageController.shared.typing(msg: data, channelID: channelid)
                            }
                        case "USER_UPDATE": break
                        case "GUILD_MEMBER_LIST_UPDATE":
//                            do {
//                                let list = try JSONDecoder().decode(MemberListUpdate.self, from: textData)
//                                MessageController.shared.sendMemberList(msg: list)
//                            } catch { }
                            break
                        default: print("not handled: \(payload["t"]!)"); break
                        }
                    }
                    self?.receive() // call back the function, creating a loop
                case .data(_): break
                @unknown default: break
                }
            case .failure(let error):
                releaseModePrint(" Error when receiving loop \(error)")
                print("RECONNECT")
            }
        }
    }
}

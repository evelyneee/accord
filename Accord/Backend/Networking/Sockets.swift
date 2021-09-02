//
//  Sockets.swift
//  Accord
//
//  Created by evelyn on 2021-06-05.
//

import Foundation
import Combine

struct AnyEncodable : Encodable {
    var value: Encodable
    init(_ value: Encodable) {
        self.value = value
    }
    func encode(to encoder: Encoder) throws {
        let container = encoder.singleValueContainer()
        try value.encode(to: container as! Encoder)
    }
}

final class Notifications {
    static var shared = Notifications()
    final var notifications: [(String, String)] = [] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "Notification"), object: nil, userInfo: ["info":(self.notifications.first) ?? [:]])
            }
        }
    }
    final var privateChannels: [String] = [] {
        didSet {
            print("private", privateChannels)
        }
    }
    final func clearNotifications(forSet: (String, String)) {
        for (i, notif) in notifications.enumerated() {
            if notif == forSet {
                notifications.remove(at: i)
            }
        }
    }
}

final class WebSocketHandler {
    static var shared: WebSocketHandler = WebSocketHandler()
    var connected = false
    var session_id: String? = nil
    var seq: Int? = nil
    var heartbeat_interval: Int? = nil
    var requests: Int = 0
    let webSocketDelegate = WebSocketDelegate()
    let session: URLSession
    let ClassWebSocketTask: URLSessionWebSocketTask!

    init(url: URL? = URL(string: "wss://gateway.discord.gg?v=9&encoding=json")) {
        let config = URLSessionConfiguration.default

        // MARK: - SOCKS Proxy
        if proxyEnabled {
            config.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            config.connectionProxyDictionary = [AnyHashable: Any]()
            config.connectionProxyDictionary?[kCFNetworkProxiesHTTPEnable as String] = 1
            if let ip = proxyIP {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPProxy as String] = ip
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSProxy as String] = ip
            }
            if let port = proxyPort {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPPort as String] = Int(port)
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSPort as String] = Int(port)
            }
        }
        session = URLSession(configuration: config, delegate: webSocketDelegate, delegateQueue: nil)
        ClassWebSocketTask = session.webSocketTask(with: URL(string: "wss://gateway.discord.gg?v=9&encoding=json")!)
        ClassWebSocketTask.maximumMessageSize = 9999999999
        ClassWebSocketTask.resume()
        releaseModePrint("[Accord] Socket initiated")
    }

    final class func connect(opcode: Int = 1, channel: String? = nil, guild: String? = nil, _ completion: @escaping ((_ success: Bool, _ array: GatewayD?) -> Void)) {
        let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            WebSocketHandler.shared.requests = 0
        }

        if !(WebSocketHandler.shared.connected) {
            WebSocketHandler.shared.initialReception()
            ping()
            WebSocketHandler.shared.authenticate()
            receive()
            WebSocketHandler.shared.connected = true
        } else {
            print("[Accord] already connected, continuing")
        }

        func ping() {
            if WebSocketHandler.shared.requests >= 49 {
                return
            }
            WebSocketHandler.shared.ClassWebSocketTask!.sendPing { error in
                WebSocketHandler.shared.requests += 1
                if let error = error {
                    releaseModePrint("[Accord] Error when sending PING \(error)")
                    return completion(false, nil)
                } else {
                    print("[Accord] Web Socket connection is alive")
                }
            }
        }
        func receive() {
            if WebSocketHandler.shared.requests >= 49 {
                return
            }
            WebSocketHandler.shared.ClassWebSocketTask!.receive { result in
                WebSocketHandler.shared.requests += 1
                switch result {
                    case .success(let message):
                        switch message {
                        case .data(let data):
                            print("[Accord] Data received \(data)")
                        case .string(let text):
                            if let textData = text.data(using: String.Encoding.utf8) {
                                let payload = WebSocketHandler.shared.decodePayload(payload: textData)
                                if payload["s"] as? Int != nil {
                                    WebSocketHandler.shared.seq = payload["s"] as? Int
                                } else {
                                    if (payload["op"] as? Int ?? 0) != 11 {
                                        print("[Accord] RECONNECT")
                                        WebSocketHandler.shared.reconnect()
                                        sleep(2)
                                    } else {
                                        print("[Accord] HEARTBEAT SUCCESSFUL")
                                    }
                                }
                                socketEvents.append(["\(payload["t"] as? String ?? "") <~":String(describing: payload["d"])])
                                switch payload["t"] as? String ?? "" {
                                case "READY":
                                    let path = FileManager.default.urls(for: .cachesDirectory,
                                                                        in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                                    try! textData.write(to: path)
                                    let structure = try! JSONDecoder().decode(GatewayStructure.self, from: textData)
                                    releaseModePrint("[Accord] Gateway ready (\(structure.d.v), \(structure.d.user.username)#\(structure.d.user.discriminator))")
                                    WebSocketHandler.shared.session_id = structure.d.session_id
                                    completion(true, structure.d)
                                    break

                                // MARK: Channel Event Handlers
                                case "CHANNEL_CREATE": break
                                case "CHANNEL_UPDATE": break
                                case "CHANNEL_DELETE": break
                                case "CHANNEL_PINS_UPDATE": break

                                // MARK: Guild Event Handlers
                                case "GUILD_CREATE": print("[Accord] something was created"); break
                                case "GUILD_UPDATE": break
                                case "GUILD_DELETE": break
                                case "GUILD_BAN_ADD": break
                                case "GUILD_BAN_REMOVE": break
                                case "GUILD_EMOJIS_UPDATE": break
                                case "GUILD_MEMBER_ADD": break
                                case "GUILD_MEMBER_REMOVE": break
                                case "GUILD_MEMBER_UPDATE": break
                                case "GUILD_MEMBERS_CHUNK":
                                    DispatchQueue.main.async {
                                        MessageController.shared.sendMemberChunk(msg: textData)
                                    }
                                    break
                                case "GUILD_ROLE_CREATE": break
                                case "GUILD_ROLE_UPDATE": break
                                case "GUILD_ROLE_DELETE": break

                                // MARK: Integration Event Handlers
                                case "INTEGRATION_CREATE": break
                                case "INTEGRATION_UPDATE": break
                                case "INTEGRATION_DELETE": break

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
                                        Notifications.shared.notifications.append((data["guild_id"] as? String ?? "@me", data["channel_id"] as! String))
                                    } else if Notifications.shared.privateChannels.contains(data["id"] as! String) {
                                        print("[Accord] NOTIFICATION SENDING NOW")
                                        showNotification(title: (((payload["d"] as! [String: Any])["author"]) as! [String:Any])["username"] as? String ?? "", subtitle: (payload["d"] as! [String: Any])["content"] as! String)
                                        Notifications.shared.notifications.append(("@me", data["channel_id"] as! String))
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

                                // MARK: Voice Event Handler
                                case "VOICE_STATE_UPDATE": break
                                case "VOICE_SERVER_UPDATE": break

                                // MARK: Webhooks Event Handler
                                case "WEBHOOKS_UPDATE": break
                                default: break
                                }
                            }
                            receive() // call back the function, creating a loop
                        @unknown default:
                            print("[Accord] unknown")
                        }
                case .failure(let error):
                    releaseModePrint("[Accord] Error when receiving loop \(error)")
                    print("[Accord] RECONNECT")
                    WebSocketHandler.shared.reconnect()
                }
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
        if self.requests >= 49 {
            return
        }
        WebSocketHandler.shared.ClassWebSocketTask!.receive { result in
            WebSocketHandler.shared.requests += 1
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    break
                case .string(let text):
                    if let data = text.data(using: String.Encoding.utf8) {
                        let hello = self.decodePayload(payload: data)
                        WebSocketHandler.shared.heartbeat_interval = (hello["d"] as? [String:Any] ?? [:])["heartbeat_interval"] as? Int ?? 0
                        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(WebSocketHandler.shared.heartbeat_interval ?? 0), execute: {
                            WebSocketHandler.shared.heartbeat()
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

    // MARK: ACK
    func heartbeat() {
        if WebSocketHandler.shared.requests >= 49 {
            return
        }
        let packet: [String:AnyEncodable] = [
            "op":AnyEncodable(1),
            "d":AnyEncodable(WebSocketHandler.shared.seq)
        ]
        socketEvents.append(["heartbeat (op 9) ~>":String(describing: packet as [String:Any])])
        if let jsonData = try? JSONEncoder().encode(packet),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            WebSocketHandler.shared.ClassWebSocketTask!.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
                print("[Accord] heartbeat")
                WebSocketHandler.shared.requests += 1
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(WebSocketHandler.shared.heartbeat_interval ?? 0), execute: { [weak self] in
                    self?.heartbeat()
                })
            }
        }
    }

    // MARK: Authentication
    func authenticate() {
        let packet: [String:AnyEncodable] = [
            "op":AnyEncodable(2),
            "d":AnyEncodable([
                "token":AnyEncodable(AccordCoreVars.shared.token),
                "capabilities":AnyEncodable(125),
                "compress":AnyEncodable(false),
                "properties": AnyEncodable([
                    "os":AnyEncodable("Mac OS X"),
                    "browser":AnyEncodable("Discord Client"),
                    "release_channel":AnyEncodable("canary"),
                    "client_build_number": AnyEncodable(93654),
                    "client_version":AnyEncodable("0.0.273"),
                    "os_version":AnyEncodable("21.0.0"),
                    "os_arch":AnyEncodable("x64"),
                    "system-locale":AnyEncodable("en-US"),
                ] as [String:AnyEncodable])
            ] as [String:AnyEncodable])
        ]
        socketEvents.append(["identify (op 2) ~>":String(describing: packet as [String:Any])])
        if let jsonData = try? JSONEncoder().encode(packet),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            WebSocketHandler.shared.ClassWebSocketTask!.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }

    final func close() {
        let reason = "Closing connection".data(using: .utf8)
        ClassWebSocketTask!.cancel(with: .goingAway, reason: reason)
    }
    final func reconnect() {
        let packet: [String:AnyEncodable] = [
            "op":AnyEncodable(Int(6)),
            "d":AnyEncodable([
                "token":AnyEncodable(AccordCoreVars.shared.token),
                "session_id":AnyEncodable(String(WebSocketHandler.shared.session_id ?? "")),
                "seq":AnyEncodable(Int(WebSocketHandler.shared.seq ?? 0))
            ] as [String:AnyEncodable])
        ]
        if let jsonData = try? JSONEncoder().encode(packet),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ClassWebSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
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
            ClassWebSocketTask.send(.string(jsonString)) { error in
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
            ClassWebSocketTask.send(.string(jsonString)) { error in
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }
    final func getMembers(ids: [String], guild: String, _ completion: @escaping ((_ success: Bool, _ users: [GuildMember?]) -> Void)) {
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
            self.ClassWebSocketTask.send(.string(jsonString)) { error in
                print("[Accord] SENT \(jsonString)")
                self.ClassWebSocketTask.receive { result in
                    switch result {
                    case .success(let message):
                        switch message {
                        case .data(_):
                            break
                        case .string(let text):
                            print(text, "MEMBER CHUNK")
                            break
                        @unknown default:
                            print("[Accord] unknown")
                            break
                        }
                    case .failure(let error):
                        print("[Accord] Error when init receiving \(error)")
                    }
                }
                if let error = error {
                    releaseModePrint("[Accord] WebSocket sending error: \(error)")
                }
            }
        }
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String { get }
}

final class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        releaseModePrint("[Accord] Web Socket did connect")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        releaseModePrint("[Accord] Web Socket did disconnect")
        let reason = String(decoding: reason ?? Data(), as: UTF8.self)
        MessageController.shared.sendWSError(msg: reason)
        print("[Accord] Error from Discord: \(reason)")
        // MARK: WebSocket close codes.
        switch closeCode {
        case .invalid:
            Swift.fatalError("Socket closed because payload was invalid")
        case .normalClosure:
            releaseModePrint("[Accord] Socket closed because connection was closed")
            Swift.fatalError(reason)
        case .goingAway:
            releaseModePrint("[Accord] Socket closed because connection was closed")
            Swift.fatalError(reason)
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
            print("[Accord] Socket closed because an extension was missing")
        case .internalServerError:
            Swift.fatalError("Socket closed because there was an internal server error")
        case .tlsHandshakeFailure:
            releaseModePrint("[Accord] Socket closed because the tls handshake failed")
        @unknown default:
            releaseModePrint("[Accord] Socket closed for unknown reason")
        }
    }
}

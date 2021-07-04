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

final class WebSocketHandler {
    static var shared: WebSocketHandler? = WebSocketHandler()
    var connected = false
    var session_id: String? = nil
    var seq: Int? = nil
    var heartbeat_interval: Int? = nil
    var requests: Int = 0
    let webSocketDelegate = WebSocketDelegate()
    let session: URLSession
    let ClassWebSocketTask: URLSessionWebSocketTask!

    init(url: URL? = URL(string: "wss://gateway.discord.gg")) {
        session = URLSession(configuration: .default, delegate: webSocketDelegate, delegateQueue: nil)
        ClassWebSocketTask = session.webSocketTask(with: URL(string: "wss://gateway.discord.gg")!)
        ClassWebSocketTask.resume()
        ClassWebSocketTask.maximumMessageSize = 999999999
        print("Socket initiated")
    }
    
    class func newMessage(opcode: Int = 1, channel: String? = nil, guild: String? = nil, _ completion: @escaping ((_ success: Bool, _ array: [String:Any]?) -> Void)) {
        let webSocketTask = WebSocketHandler.shared?.ClassWebSocketTask!
        let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            WebSocketHandler.shared?.requests = 0
        }
        
        if !(WebSocketHandler.shared?.connected ?? false) {
            initialReception()
            authenticate()
            receive()
            WebSocketHandler.shared?.connected = true
        } else {
            print("already connected, continuing")
        }
        
        func reconnect() {
            sleep(10)
            let packet: [String:AnyEncodable] = [
                "op":AnyEncodable(Int(6)),
                "d":AnyEncodable([
                    "token":AnyEncodable(token),
                    "session_id":AnyEncodable(String(WebSocketHandler.shared?.session_id ?? "")),
                    "seq":AnyEncodable(Int(WebSocketHandler.shared?.seq ?? 0))
                ] as [String:AnyEncodable])
            ]
            if let jsonData = try? JSONEncoder().encode(packet),
               let jsonString: String = String(data: jsonData, encoding: .utf8) {
                webSocketTask?.send(.string(jsonString)) { error in
                    if let error = error {
                        print("WebSocket sending error: \(error)")
                    }
                }
            } 
        }
        func authenticate() {
            let packet: [String:AnyEncodable] = [
                "op":AnyEncodable(2),
                "d":AnyEncodable([
                    "token":AnyEncodable(token),
                    "capabilities":AnyEncodable(125),
                    "compress":AnyEncodable(false),
                    "properties": AnyEncodable([
                        "os":AnyEncodable("macOS"),
                        "browser":AnyEncodable("Discord Client"),
                        "device":AnyEncodable("")
                    ] as [String:AnyEncodable])
                ] as [String:AnyEncodable])
            ]
            if let jsonData = try? JSONEncoder().encode(packet),
               let jsonString: String = String(data: jsonData, encoding: .utf8) {
                webSocketTask?.send(.string(jsonString)) { error in
                    if let error = error {
                        print("WebSocket sending error: \(error)")
                    }
                }
            }
        }
        func send(opcode: Int) {
            let packet: [String:AnyEncodable] = [
                "op":AnyEncodable(opcode),
                "d":AnyEncodable([
                    "properties": AnyEncodable([
                        "os":AnyEncodable("Windows"),
                        "browser":AnyEncodable("Firefox"),
                        "device":AnyEncodable("")
                    ] as [String:AnyEncodable])
                ] as [String:AnyEncodable])
            ]
            if let jsonData = try? JSONEncoder().encode(packet),
               let jsonString: String = String(data: jsonData, encoding: .utf8) {
                webSocketTask?.send(.string(jsonString)) { error in
                    receive()
                    if let error = error {
                        print("WebSocket sending error: \(error)")
                    }
                }
            }
        }
        func heartbeat() {
            if WebSocketHandler.shared!.requests >= 49 {
                return
            }
            let packet: [String:AnyEncodable] = [
                "op":AnyEncodable(1),
                "d":AnyEncodable(WebSocketHandler.shared?.seq)
            ]
            if let jsonData = try? JSONEncoder().encode(packet),
               let jsonString: String = String(data: jsonData, encoding: .utf8) {
                webSocketTask?.send(.string(jsonString)) { error in
                    if let error = error {
                        print("WebSocket sending error: \(error)")
                    }
                    print("heartbeat")
                    WebSocketHandler.shared?.requests += 1
                    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(WebSocketHandler.shared?.heartbeat_interval ?? 0), execute: {
                        heartbeat()
                    })
                }
            }
        }


        func ping() {
            if WebSocketHandler.shared!.requests >= 49 {
                return
            }
            webSocketTask?.sendPing { error in
                WebSocketHandler.shared?.requests += 1
                if let error = error {
                    print("Error when sending PING \(error)")
                } else {
                    print("Web Socket connection is alive")
                    sleep(3)
                    ping()
                }
            }
        }
        func initialReception() {
            if WebSocketHandler.shared!.requests >= 49 {
                return
            }
            webSocketTask?.receive { result in
                WebSocketHandler.shared?.requests += 1
                switch result {
                case .success(let message):
                    switch message {
                    case .data(_):
                        break
                    case .string(let text):
                        if let data = text.data(using: String.Encoding.utf8) {
                            let hello = decodePayload(payload: data)
                            WebSocketHandler.shared?.heartbeat_interval = (hello["d"] as? [String:Any] ?? [:])["heartbeat_interval"] as? Int ?? 0
                            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(WebSocketHandler.shared?.heartbeat_interval ?? 0), execute: {
                                heartbeat()
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
        func receive() {
            if WebSocketHandler.shared!.requests >= 49 {
                return
            }
            webSocketTask?.receive { result in
                WebSocketHandler.shared?.requests += 1
                switch result {
                    case .success(let message):
                        switch message {
                        case .data(let data):
                            print("Data received \(data)")
                        case .string(let text):
                            if let textData = text.data(using: String.Encoding.utf8) {
                                let payload = decodePayload(payload: textData)
                                if payload["s"] as? Int != nil {
                                    WebSocketHandler.shared?.seq = payload["s"] as? Int
                                } else {
                                    if (payload["op"] as? Int ?? 0) != 11 {
                                        print("RECONNECT")
                                        reconnect()
                                        sleep(2)
                                    } else {
                                        print("HEARTBEAT SUCCESSFUL")
                                    }
                                }
                                print(payload["t"])
                                switch payload["t"] as? String ?? "" {
                                case "READY":
                                    let data = payload["d"] as! [String: Any]
                                    let user = data["user"] as! [String: Any]
                                    print("Gateway ready (\(data["v"] as! Int), \(user["username"] as! String)#\(user["discriminator"] as! String))")
                                    WebSocketHandler.shared?.session_id = data["session_id"] as? String
                                    completion(true, data)
                                    break

                                // MARK: Channel Event Handlers
                                case "CHANNEL_CREATE": break
                                case "CHANNEL_UPDATE": break
                                case "CHANNEL_DELETE": break
                                case "CHANNEL_PINS_UPDATE": break

                                // MARK: Guild Event Handlers
                                case "GUILD_CREATE": print("something was created"); break
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
                                        NotificationCenter.default.post(name: Notification.Name(rawValue: "MemberChunk"), object: nil, userInfo: ["users":textData])
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
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "NewMessageIn\(channelid)"), object: nil, userInfo: ["data":textData])
                                        }
                                    }
                                    if (((payload["d"] as! [String: Any])["mentions"] as? [[String:Any]] ?? []).map { $0["id"] as? String ?? ""}).contains(user_id) {
                                        print("NOTIFICATION SENDING NOW")
                                        showNotification(title: (((payload["d"] as! [String: Any])["author"]) as! [String:Any])["username"] as? String ?? "", subtitle: (payload["d"] as! [String: Any])["content"] as! String)
                                    }
                                    break
                                case "MESSAGE_UPDATE":
                                    let data = payload["d"] as! [String: Any]
                                    if let channelid = data["channel_id"] as? String {
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "EditedMessageIn\(channelid)"), object: nil, userInfo: ["data":textData])
                                        }
                                    }
                                    break
                                case "MESSAGE_DELETE":
                                    let data = payload["d"] as! [String: Any]
                                    if let channelid = data["channel_id"] as? String {
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "DeletedMessageIn\(channelid)"), object: nil, userInfo: ["data":textData])
                                        }
                                    }
                                    break
                                case "MESSAGE_REACTION_ADD": print("something was created"); break
                                case "MESSAGE_REACTION_REMOVE": print("something was created"); break
                                case "MESSAGE_REACTION_REMOVE_ALL": print("something was created"); break
                                case "MESSAGE_REACTION_REMOVE_EMOJI": print("something was created"); break

                                // MARK: Presence Event Handlers
                                case "PRESENCE_UPDATE": break
                                case "TYPING_START":
                                    print("notified", "TYPING")
                                    let data = payload["d"] as! [String: Any]
                                    if let channelid = data["channel_id"] as? String {
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "TypingStartIn\(channelid)"), object: nil, userInfo: data)
                                            print("notified", data, "TYPING")
                                        }
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
                            print("unknown")
                        }
                case .failure(let error):
                    print("Error when receiving loop \(error)")
                    print("RECONNECT")
                    reconnect()
                }
            }
        }
        func close() {
            let reason = "Closing connection".data(using: .utf8)
            webSocketTask?.cancel(with: .goingAway, reason: reason)
        }
        func checkConnection(_ completion: @escaping ((_ success: Bool, _ array: [String:Any]?) -> Void)) {
            webSocketTask?.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .data(_):
                        break
                    case .string(let text):
                        if let data = text.data(using: String.Encoding.utf8) {
                            do {
                                let tempretDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] ?? [:]
                                let retDict = (tempretDict["d"] as? [String:Any] ?? [:])
                                return completion(true, retDict)

                            } catch let error as NSError {
                                print(error)
                                return completion(false, nil)
                            }
                        }
                    @unknown default:
                        print("unknown")
                    }
                case .failure(let error):
                    print("Error when receiving massive \(error)")
                }
            }
        }
        func decodePayload(payload: Data) -> [String: Any] {
            do {
                return try JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any] ?? [:]
            } catch {
                return [:]
            }
        }
        
    }
    func subscribe(_ guild: String, _ channel: String) {
        let packet: [String:Any] = [
            "op":14,
            "d": [
                "guild_id":guild,
                "typing":true,
                "activities":true,
                "threads":false,
                "members":[],
                "channels": [
                    channel: [["0", "99"]]
                ],
            ],
        ]
        print(guild, channel)
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: .prettyPrinted),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ClassWebSocketTask.send(.string(jsonString)) { error in
                print("SENT \(jsonString)")
                if let error = error {
                    print("WebSocket sending error: \(error)")
                }
            }
        }
    }
    func reconnect() {
        sleep(10)
        let packet: [String:AnyEncodable] = [
            "op":AnyEncodable(Int(6)),
            "d":AnyEncodable([
                "token":AnyEncodable(token),
                "session_id":AnyEncodable(String(WebSocketHandler.shared?.session_id ?? "")),
                "seq":AnyEncodable(Int(WebSocketHandler.shared?.seq ?? 0))
            ] as [String:AnyEncodable])
        ]
        if let jsonData = try? JSONEncoder().encode(packet),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ClassWebSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    print("WebSocket sending error: \(error)")
                }
                return
            }
        }
    }
    func getMembers(ids: [String], guild: String, _ completion: @escaping ((_ success: Bool, _ users: [GuildMember?]) -> Void)) {
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
            self.ClassWebSocketTask.send(.string(jsonString)) { error in
                print("SENT \(jsonString)")
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
                            print("unknown")
                            break
                        }
                    case .failure(let error):
                        print("Error when init receiving \(error)")
                    }
                }
                if let error = error {
                    print("WebSocket sending error: \(error)")
                }
            }
        }
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }
            
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
        let reason = String(decoding: reason ?? Data(), as: UTF8.self)
        print("Error from Discord: \(reason)")
        switch closeCode {
        case .invalid:
            fatalError("Socket closed because payload was invalid")
        case .normalClosure:
            print("Socket closed because connection was closed")
            fatalError(reason)
        case .goingAway:
            print("Socket closed because connection was closed")
            fatalError(reason)
        case .protocolError:
            print("Socket closed because there was a protocol error")
        case .unsupportedData:
            print("Socket closed input/output data was unsupported")
        case .noStatusReceived:
            print("Socket closed no status was received")
        case .abnormalClosure:
            print("Socket closed, there was an abnormal closure")
        case .invalidFramePayloadData:
            print("Socket closed the frame data was invalid")
        case .policyViolation:
            print("Socket closed: Policy violation")
        case .messageTooBig:
            print("Socket closed because the message was too big")
        case .mandatoryExtensionMissing:
            print("Socket closed because an extension was missing")
        case .internalServerError:
            fatalError("Socket closed because there was an internal server error")
        case .tlsHandshakeFailure:
            print("Socket closed because the tls handshake failed")
        @unknown default:
            print("Socket closed for unknown reason")
        }
    }
}

//
//  Sockets.swift
//  Helselia
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

final class WebSocketHandler: NSObject, URLSessionWebSocketDelegate {
    static var shared = WebSocketHandler()
    var connected = false
    class func newMessage(opcode: Int, _ completion: @escaping ((_ success: Bool, _ array: [String:Any]?) -> Void)) {
        let webSocketDelegate = WebSocketHandler()
        let session = URLSession(configuration: .default, delegate: webSocketDelegate, delegateQueue: OperationQueue())
        let url = URL(string: "wss://gateway.discord.gg")!
        let webSocketTask = session.webSocketTask(with: url)
        webSocketTask.maximumMessageSize = 999999999
        if !(WebSocketHandler.shared.connected) {
            webSocketTask.resume()
            initialReception()
            authenticate()
            ping()
            WebSocketHandler.shared.connected = true
        } else {
            print("already connected, continuing")
        }
        func authenticate() {
            let packet: [String:AnyEncodable] = [
                "op":AnyEncodable(2),
                "d":AnyEncodable([
                    "token":AnyEncodable(token),
                    "capabilities":AnyEncodable(125),
                    "compress":AnyEncodable(false),
                    "properties": AnyEncodable([
                        "os":AnyEncodable("Windows"),
                        "browser":AnyEncodable("Firefox"),
                        "device":AnyEncodable("")
                    ] as [String:AnyEncodable])
                ] as [String:AnyEncodable])
            ]
            if let jsonData = try? JSONEncoder().encode(packet),
               let jsonString: String = String(data: jsonData, encoding: .utf8) {
                webSocketTask.send(.string(jsonString)) { error in
                    DispatchQueue.global().async {
                        receive()
                    }
                    checkConnection() {success, array in
                        if success {
                            return completion(true, array)
                        }
                    }
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
                webSocketTask.send(.string(jsonString)) { error in
                    receive()
                    if let error = error {
                        print("WebSocket sending error: \(error)")
                    }
                }
            }

        }
        func ping() {
            webSocketTask.sendPing { error in
                if let error = error {
                    print("Error when sending PING \(error)")
                } else {
                    print("Web Socket connection is alive")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        ping()
                    }
                }
            }
        }
        func initialReception() {
            webSocketTask.receive { result in
                
            }
        }
        func receive() {
            webSocketTask.receive { result in
                switch result {
                    case .success(let message):
                        switch message {
                        case .data(let data):
                            print("Data received \(data)")
                        case .string(let text):
                            if let data = text.data(using: String.Encoding.utf8) {
                                switch decodePayload(payload: data)["t"] as? String ?? "" {
                                case "READY":
                                    let data = decodePayload(payload: data)["d"] as! [String: Any]
                                    let user = data["user"] as! [String: Any]
                                    print("Gateway ready (\(data["v"] as! Int), \(user["username"] as! String)#\(user["discriminator"] as! String))")
//                                    self.clubs = data["clubs"] as? [[String: Any]]

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
                                case "GUILD_MEMBERS_CHUNK": break // In response to opcode 8 (club request members)
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
                                    let data = decodePayload(payload: data)["d"] as! [String: Any]
                                    if let channelid = data["channel_id"] as? String {
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "NewMessageIn\(channelid)"), object: nil, userInfo: data)
                                        }
                                    }
                                    break
                                case "MESSAGE_UPDATE":
                                    let data = decodePayload(payload: data)["d"] as! [String: Any]
                                    if let channelid = data["channel_id"] as? String {
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "EditedMessageIn\(channelid)"), object: nil, userInfo: data)
                                        }
                                    }
                                    break
                                case "MESSAGE_DELETE":
                                    let data = decodePayload(payload: data)["d"] as! [String: Any]
                                    if let channelid = data["channel_id"] as? String {
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "DeletedMessageIn\(channelid)"), object: nil, userInfo: data)
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
                                    let data = decodePayload(payload: data)["d"] as! [String: Any]
                                    print("notified", data, "TYPING")
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
                    print("Error when receiving \(error)")
                    break
                }
            }
        }
        func close() {
            let reason = "Closing connection".data(using: .utf8)
            webSocketTask.cancel(with: .goingAway, reason: reason)
        }
        func checkConnection(_ completion: @escaping ((_ success: Bool, _ array: [String:Any]?) -> Void)) {
            var retValue: Bool = false {
                didSet {
                    print("set that \(retValue)")
                }
            }
            var _: Bool = false
            var retDict: [String:Any] = [:]
            webSocketTask.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data):
                        retValue = false
                    case .string(let text):
                        if let data = text.data(using: String.Encoding.utf8) {
                            do {
                                let tempretDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] ?? [:]
                                retDict = (tempretDict["d"] as? [String:Any] ?? [:])
                                return completion(true, retDict)

                            } catch let error as NSError {
                                print(error)
                                return completion(false, nil)
                            }
                        }
                    @unknown default:
                        print("unknown")
                        retValue = false
                    }
                case .failure(let error):
                    print("Error when receiving \(error)")
                    retValue = false
                }
            }
            return completion(false, nil)
        }
        func decodePayload(payload: Data) -> [String: Any] {
            do {
                return try JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any] ?? [:]
            } catch let error as NSError {
            }
            return [:]
        }
        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
            print("Web Socket did connect")
        }
                
        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            print("Web Socket did disconnect")
        }
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

//
//  Sockets.swift
//  Accord
//
//  Created by evelyn on 2021-06-05.
//

import Foundation
import Combine

final class Notifications {
    public static var privateChannels: [String] = []
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String { get }
}

final class WebSocket {
    
    var ws: URLSessionWebSocketTask!
    let session: URLSession
    let webSocketDelegate = WebSocketDelegate.shared
    var session_id: String? = nil
    var seq: Int? = nil
    var heartbeat_interval: Int = 0
    var cachedMemberRequest: [String:GuildMember] = [:]
    var req: Int = 0
    var waitlist: [String:[String]] = [:]
    var timer: Timer?
    var pendingHeartbeat: Bool = false
    
    private var bag = Set<AnyCancellable>()
    
    var failedHearbeats: Int = 0 {
        didSet {
            if failedHearbeats > 3 {
                wss.reset()
            }
        }
    }
    
    static var gatewayURL: URL = URL(string: "wss://gateway.discord.gg?v=9&encoding=json")!
    
    enum WebSocketErrors: Error {
        case maxRequestReached
        case essentialEventFailed(String)
    }
    
    // MARK: - init
    init(url: URL?, session_id: String? = nil, seq: Int? = nil) throws {
        
        releaseModePrint("[Socket] Hello world!")

        let config = URLSessionConfiguration.default
        
        if proxyEnabled {
            config.setProxy()
        }
        session = URLSession(configuration: config, delegate: webSocketDelegate, delegateQueue: nil)
        ws = session.webSocketTask(with: url!)
        print(ws.maximumMessageSize, "default size")
        ws.maximumMessageSize = 9999999
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { temp in
                print("reset req blocker")
                wss.req = 0
                wss.waitlist.removeAll()
            }
        }
        ws.resume()
        self.hello()
        if let session_id = session_id, let seq = seq {
            try self.reconnect(session_id: session_id, seq: seq)
        } else {
            try self.authenticate()
        }
        releaseModePrint("Socket initiated")
    }
    
    func reset() {
        ws.cancel(with: .goingAway, reason: Data())
        concurrentQueue.async {
            guard let new = try? WebSocket.init(url: WebSocket.gatewayURL, session_id: wss.session_id, seq: wss.seq) else { return }
            new.ready().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &new.bag)
            wss = new
        }
    }
    
    func hardReset() {
        wss = nil
        concurrentQueue.async {
            guard let new = try? WebSocket.init(url: WebSocket.gatewayURL) else { return }
            wss = new
        }
    }
    
    // MARK: - Ping
    func ping() {
        ws.sendPing { error in
            if let error = error {
                releaseModePrint("Error when sending PING \(error)")
            } else {
                print("Web Socket connection is alive")
            }
        }
    }
    
    // MARK: Decode payloads
    func decodePayload(payload: Data) -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: payload, options: []) as? [String:Any]
    }
    
    struct Hello: Decodable {
        var d: HelloD
        struct HelloD: Decodable {
            var heartbeat_interval: Int
        }
    }
    
    // MARK: Initial WS setup
    func hello() {
        ws.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    break
                case .string(let text):
                    if let data = text.data(using: String.Encoding.utf8) {
                        let interval = try? JSONDecoder().decode(Hello.self, from: data).d.heartbeat_interval
                        guard let interval = interval else {
                            wss.hardReset()
                            return
                        }
                        self?.heartbeat_interval = interval
                        wssThread.asyncAfter(deadline: .now() + .milliseconds(interval), execute: {
                            do {
                                try self?.heartbeat()
                            } catch {
                                self?.failedHearbeats++
                            }
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
    func ready() -> Future<GatewayD?, Error> {
        return Future { [weak ws] promise in
            ws?.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .data(_):
                        break
                    case .string(let text):
                        if let data = text.data(using: String.Encoding.utf8) {
                            do {
                                let path = FileManager.default.urls(for: .cachesDirectory,
                                                                    in: .userDomainMask)[0]
                                                                    .appendingPathComponent("socketOut.json")
                                try data.write(to: path)
                                let structure = try JSONDecoder().decode(GatewayStructure.self, from: data)
                                wssThread.async {
                                    self.receive()
                                }
                                releaseModePrint("Gateway Ready \(structure.d.user.username)#\(structure.d.user.discriminator)")
                                promise(.success(structure.d))
                                return
                            } catch {
                                promise(.failure(error))
                                return
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
    }

    
    // MARK: ACK
    func heartbeat() throws {
        print("sent heartbeat")
        guard let seq = seq, !pendingHeartbeat else {
            self.reset()
            return
        }
        let packet: [String:Any] = [
            "op":1,
            "d":seq
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { [weak self] error in
                self?.pendingHeartbeat = true
                if let _ = error {
                    try? self?.reconnect()
                }
                wssThread.asyncAfter(deadline: .now() + .milliseconds(self?.heartbeat_interval ?? 10000), execute: { [weak self] in
                    do {
                        try self?.heartbeat()
                    } catch {
                        self?.failedHearbeats++
                    }
                })
            }
        }
    }

    // MARK: Authentication
    func authenticate() throws {
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
        let jsonData = try JSONSerialization.data(withJSONObject: packet, options: [])
        let jsonString = try String(jsonData)
        ws.sendPublisher(.string(jsonString))
            .sink(receiveCompletion: { comp in
                switch comp {
                    case .finished: break
                    case .failure(let error):
                        MentionSender.shared.sendWSError(error: error)
                        break
                }
            }) { _ in }
            .store(in: &bag)
    }

    final func close() {
        let reason = "Closing connection".data(using: .utf8)
        ws.cancel(with: .goingAway, reason: reason)
    }
    
    final func reconnect(session_id: String? = nil, seq: Int? = nil) throws {
        let packet: [String:Any] = [
            "op":6,
            "d":[
                "seq":seq ?? self.seq ?? 0,
                "session_id":session_id ?? self.session_id ?? "",
                "token":AccordCoreVars.shared.token
            ]
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: packet, options: [])
        let jsonString = try String(jsonData)
        ws.sendPublisher(.string(jsonString))
            .sink(receiveCompletion: { comp in
                switch comp {
                    case .finished: break
                    case .failure(let error):
                        releaseModePrint("error reconnecting ", error)
                        self.hardReset()
                        break
                }
            }) { _ in }
            .store(in: &bag)
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
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    MentionSender.shared.sendWSError(error: error)
                    releaseModePrint("WebSocket sending error: \(error)")
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
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                if let error = error {
                    MentionSender.shared.sendWSError(error: error)
                    releaseModePrint("WebSocket sending error: \(error)")
                }
            }
        }
    }
    
    final func getMembers(ids: [String], guild: String) throws {
        guard req <= 30 else {
            print("blocked req")
            waitlist[guild]?.append(contentsOf: ids)
            throw WebSocketErrors.maxRequestReached
        }
        print("fetched")
        let packet: [String:Any] = [
            "op":8,
            "d": [
                "limit":0,
                "user_ids":ids,
                "guild_id":guild
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
           let jsonString: String = String(data: jsonData, encoding: .utf8) {
            ws.send(.string(jsonString)) { error in
                self.req++
                if let error = error {
                    MentionSender.shared.sendWSError(error: error)
                    releaseModePrint("WebSocket sending error: \(error)")
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
                                self?.pendingHeartbeat = false
                                self?.receive()
                            } else {
                                // disconnected?
                                try? self?.reconnect()
                            }
                            return
                        }
                        self?.seq = s
                        guard let t = payload["t"] as? String else {
                            self?.receive()
                            return
                        }
                        print("t: \(t)")
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
                        case "GUILD_CREATE": print("guild created"); break
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
                            print("notification 1")
                            let guild_id = dict["guild_id"] as? String ?? "@me"
                            guard let channel_id = dict["channel_id"] as? String else { break }
                            print("notification 2")
                            guard let author = dict["author"] as? [String:Any] else { break }
                            guard let username = author["username"] as? String else { break }
                            guard let userID = author["id"] as? String else { break }
                            print("notification 3")
                            guard let content = dict["content"] as? String else { break }
                            if ids.contains(user_id) {
                                print("notification")
                                showNotification(title: username, subtitle: content)
                                MentionSender.shared.addMention(guild: guild_id, channel: channel_id)
                            } else if Notifications.privateChannels.contains(channel_id) && userID != user_id {
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
                        case "READY_SUPPLEMENTAL": break
                        case "GUILD_MEMBER_LIST_UPDATE":
//                            do {
//                                let list = try JSONDecoder().decode(MemberListUpdate.self, from: textData)
//                                MessageController.shared.sendMemberList(msg: list)
//                            } catch { }
                            break
                        default: break
                        }
                    }
                    self?.receive() // call back the function, creating a loop
                case .data(_): break
                @unknown default: break
                }
            case .failure(let error):
                releaseModePrint(" Error when receiving loop \(error)")
                print("RECONNECT")
                MentionSender.shared.sendWSError(error: error)
            }
        }
    }
}

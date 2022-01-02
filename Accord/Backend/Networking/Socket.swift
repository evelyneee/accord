//
//  Gateway.swift
//  Accord
//
//  Created by evelyn on 2021-06-05.
//

import Foundation
import Combine
import Network

final class Notifications {
    public static var privateChannels: [String] = []
}

/*
 final class GatewayOld {

    var ws: URLSessionWebSocketTask!
    let session: URLSession
    weak var webSocketDelegate = WebSocketDelegate.shared
    var session_id: String?
    var seq: Int?
    var heartbeat_interval: Int = 0
    var cachedMemberRequest: [String: GuildMember] = [:]
    var req: Int = 0
    var waitlist: [String: [String]] = [:]
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
            self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
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
            guard let new = try? Gateway.init(url: Gateway.gatewayURL, session_id: wss.session_id, seq: wss.seq) else { return }
            new.ready().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &new.bag)
            wss = new
        }
    }

    func hardReset() {
        wss = nil
        concurrentQueue.async {
            guard let new = try? Gateway.init(url: Gateway.gatewayURL) else { return }
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
        return try? JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any]
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
                case .data:
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
                    case .data:
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
        let packet: [String: Any] = [
            "op": 1,
            "d": seq
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
        let packet: [String: Any] = [
            "op": 2,
            "d": [
                "token": AccordCoreVars.token,
                "capabilities": 253,
                "compress": false,
                "client_state":[
                    "guild_hashes":[:],
                    "highest_last_message_id":"0",
                    "read_state_version":0,
                    "user_guild_settings_version":-1,
                    "user_settings_version":-1
                ],
                "presence":[
                    "activities":[],
                    "afk":false,
                    "since":0,
                    "status":"online"
                ],
                "properties": [
                    "os": "Mac OS X",
                    "browser": "Discord Client",
                    "release_channel": "stable",
                    "client_build_number": dscVersion,
                    "client_version": "0.0.264",
                    "os_version": NSWorkspace.kernelVersion,
                    "os_arch": NSRunningApplication.current.executableArchitecture == NSBundleExecutableArchitectureX86_64 ? "x64" : "arm64",
                    "system-locale": NSLocale.current.languageCode ?? "en-US"
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

    func updatePresence(status: String, since: Int, activities: [Activity]) throws {
        let packet: [String:Any] = [
            "op":3,
            "d": [
                "status":status,
                "since":since,
                "activities": activities.map { $0.dictValue },
                "afk":false
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
        let packet: [String: Any] = [
            "op": 6,
            "d": [
                "seq": seq ?? self.seq ?? 0,
                "session_id": session_id ?? self.session_id ?? "",
                "token": AccordCoreVars.token
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
        let packet: [String: Any] = [
            "op": 14,
            "d": [
                "guild_id": guild,
                "typing": true,
                "activities": true,
                "threads": true,
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
    
    final func memberList(for guild: String, in channel: String) {
        let packet: [String: Any] = [
            "op": 14,
            "d": [
                "channels":[
                    channel:[[
                        0, 99
                    ]]
                ],
                "guild_id": guild
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
        let packet: [String: Any] = [
            "op": 13,
            "d": [
                "channel_id": channel
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
        let packet: [String: Any] = [
            "op": 8,
            "d": [
                "limit": 0,
                "user_ids": ids,
                "guild_id": guild
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
}
 */

extension Gateway {
    func close(_ closeCode: NWProtocolWebSocket.CloseCode) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .close)
        metadata.closeCode = closeCode
        let context = NWConnection.ContentContext(identifier: "closeContext",
                                                  metadata: [metadata])
        
        self.connection?.send(content: nil, contentContext: context, isComplete: true, completion: .contentProcessed { error in
            if let error = error {
                print(error, "close error")
            }
        })
    }
    
    func send<S: Collection>(text: S) throws where S.Element == Character {
        let context = NWConnection.ContentContext(
            identifier: "textContext",
            metadata: [NWProtocolWebSocket.Metadata(opcode: .text)]
        )
        let string = String(text)
        guard let data = string.data(using: .utf8) else { throw GatewayErrors.noStringData(string) }
        self.connection?.send(content: data, contentContext: context, completion: .contentProcessed { error in
            if let error = error {
                print(error)
            }
        })
    }
    
    func reset() {
        self.close(.protocolCode(.protocolError))
        self.connection?.receiveMessage(completion: { data, context, _, _ in
            print(String(data: data ?? Data(), encoding: .utf8))
            print(context)
            print("piss")
        })
        concurrentQueue.async {
            guard let new = try? Gateway.init(url: Gateway.gatewayURL, session_id: wss.session_id, seq: wss.seq) else { return }
            wss = new
        }
    }

    func hardReset() {
        self.close(.protocolCode(.normalClosure))
        concurrentQueue.async {
            guard let new = try? Gateway.init(url: Gateway.gatewayURL) else { return }
            new.ready().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &new.bag)
            wss = new
        }
    }
}

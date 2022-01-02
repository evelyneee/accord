//
//  Gateway.swift
//  Accord
//
//  Created by evelyn on 2022-01-01.
//

import Foundation
import Combine
import Network
import AppKit

// The second version of Accord's gateway.
// This uses Network.framework instead of URLSessionWebSocketTask
final class Gateway {
    
    private (set) var connection: NWConnection?
    private (set) var sessionID: String? = nil
    private (set) var interval: Int = 40000
    private (set) var failedHeartbeats: Int = 0
    
    internal var bag = Set<AnyCancellable>()
    internal var pendingHeartbeat: Bool = false
    internal var seq: Int = 0
    
    // To communicate with the view
    private (set) var messageSubject = PassthroughSubject<(Data, String, Bool), Never>()
    private (set) var editSubject = PassthroughSubject<(Data, String), Never>()
    private (set) var deleteSubject = PassthroughSubject<(Data, String), Never>()
    private (set) var typingSubject = PassthroughSubject<(Data, String), Never>()
    private (set) var memberChunkSubject = PassthroughSubject<Data, Never>()
    private (set) var memberListSubject = PassthroughSubject<MemberListUpdate, Never>()
    
    private (set) var stateUpdateHandler: (NWConnection.State) -> Void = { state in
        if state == .ready {
            print("socket ready")
        }
    }
    
    private let socketEndpoint: NWEndpoint
    private let params: NWParameters
    
    private var heartbeatTimer: Cancellable? = nil
    
    private var req: Int = 0
    
    public var cachedMemberRequest: [String: GuildMember] = [:]
    
    enum GatewayErrors: Error {
        case noStringData(String)
        case maxRequestReached
        case essentialEventFailed(String)
        case noSession
    }
    
    static var gatewayURL: URL = URL(string: "wss://gateway.discord.gg?v=9&encoding=json")!
    
    init(url: URL = Gateway.gatewayURL, session_id: String? = nil, seq: Int? = nil) throws {
        self.socketEndpoint = NWEndpoint.url(url)
        let parameters: NWParameters = .tls
        let websocketOptions = NWProtocolWebSocket.Options()
        websocketOptions.autoReplyPing = true
        websocketOptions.maximumMessageSize = 1_104_857_600
        parameters.defaultProtocolStack.applicationProtocols.insert(
            websocketOptions,
            at: 0
        )
        self.params = parameters
        self.connection = NWConnection(to: self.socketEndpoint, using: parameters)
        self.connection?.stateUpdateHandler = self.stateUpdateHandler
        try self.connect(session_id, seq)
    }
    
    private func connect(_ session_id: String? = nil, _ seq: Int? = nil) throws {
        connection?.start(queue: concurrentQueue)
        self.hello(session_id, seq)
    }
    
    private func hello(_ session_id: String? = nil, _ seq: Int? = nil) {
        guard connection?.state != .cancelled else { return } // Don't listen for hello if there is no connection
        connection?.receiveMessage { [weak self] (data, context, _, error) in
            if let error = error {
                print(error)
            }
            guard let data = data else {
                print(context as Any, data as Any)
                wss.hardReset()
                return
            }
            guard let hello = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
                  let helloD = hello["d"] as? [String:Any],
                  let interval = helloD["heartbeat_interval"] as? Int else { fatalError("[Gateway] No interval received in HELLO packet") }
            self?.interval = interval
            self?.heartbeatTimer = Timer.publish(every: Double(interval / 1000), on: .main, in: .default)
                .autoconnect()
                .sink { _ in
                    wssThread.async {
                        do {
                            try self?.heartbeat()
                        } catch {
                            print("[Gateway] Error sending heartbeat", error)
                            self?.failedHeartbeats++
                        }
                    }
                }
            do {
                if let session_id = session_id, let seq = seq {
                    try self?.reconnect(session_id: session_id, seq: seq)
                } else {
                    try self?.identify()
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func listen(repeat: Bool = true) {
        guard connection?.state != .cancelled else { return }
        connection?.receiveMessage { (data, context, _, error) in
            if let error = error {
                print(error)
            } else {
                self.listen()
            }
            guard let info = context?.protocolMetadata.first as? NWProtocolWebSocket.Metadata,
                  let data = data else {
                      print(context as Any, data as Any)
                      return
                  }
            switch info.opcode {
            case .text:
                self.handleMessage(textData: data)
            case .cont:
                break
            case .binary:
                break
            case .close:
                print(String(data: data, encoding: .utf8) ?? "Unknown close code")
            case .ping:
                break
            case .pong:
                break
            @unknown default:
                fatalError()
            }
        }
    }
    
    private func identify() throws {
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
        try self.send(text: jsonString)
    }

    // MARK: - Ready
    @inlinable func ready() -> Future<GatewayD, Error> {
        Future { [weak self] promise in
            print("begin receive")
            self?.connection?.receiveMessage { (data, context, _, error) in
                if let error = error {
                    print(error)
                }
                guard let info = context?.protocolMetadata.first as? NWProtocolWebSocket.Metadata,
                      let data = data else {
                          print(context as Any, data as Any)
                          return
                      }
                switch info.opcode {
                case .text:
                    do {
                        print("ready")
                        let path = FileManager.default.urls(for: .cachesDirectory,
                                                            in: .userDomainMask)[0]
                                                            .appendingPathComponent("socketOut.json")
                        try data.write(to: path)
                        let structure = try JSONDecoder().decode(GatewayStructure.self, from: data)
                        wssThread.async {
                            self?.listen()
                        }
                        releaseModePrint("Gateway Ready \(structure.d.user.username)#\(structure.d.user.discriminator)")
                        self?.sessionID = structure.d.session_id
                        print(structure.d.session_id)
                        promise(.success(structure.d))
                        return
                    } catch {
                        print(error)
                        promise(.failure(error))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                            wss.hardReset()
                        })
                        return
                    }
                case .cont:
                    break
                case .binary:
                    break
                case .close:
                    print(String(data: data, encoding: .utf8) ?? "Unknown close code")
                case .ping:
                    break
                case .pong:
                    break
                @unknown default:
                    fatalError()
                }
            }
        }
    }

    // MARK: ACK
    private func heartbeat() throws {
        if self.failedHeartbeats >= 3 {
            self.reset()
            return
        }
        let packet: [String: Any] = [
            "op": 1,
            "d": seq
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: packet, options: [])
        let jsonString = try String(jsonData)
        try self.send(text: jsonString)
        self.pendingHeartbeat = true
    }

    public func updatePresence(status: String, since: Int, activities: [Activity]) throws {
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
        try self.send(text: jsonString)
    }

    public func reconnect(session_id: String? = nil, seq: Int? = nil) throws {
        let packet: [String: Any] = [
            "op": 6,
            "d": [
                "seq": seq ?? self.seq,
                "session_id": session_id ?? self.sessionID ?? "",
                "token": AccordCoreVars.token
            ]
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: packet, options: [])
        let jsonString = try String(jsonData)
        try self.send(text: jsonString)
        wssThread.async {
            self.listen()
        }
    }

    public func subscribe(to guild: String) {
        let packet: [String: Any] = [
            "op": 14,
            "d": [
                "guild_id": guild,
                "typing": true,
                "activities": true,
                "threads": true,
            ]
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
              let jsonString = try? String(jsonData) else { return }
        try? self.send(text: jsonString)
    }
    
    public func memberList(for guild: String, in channel: String) {
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
        guard let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
              let jsonString = try? String(jsonData) else { return }
        try? self.send(text: jsonString)
    }

    public func subscribeToDM(_ channel: String) {
        let packet: [String: Any] = [
            "op": 13,
            "d": [
                "channel_id": channel
            ]
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
              let jsonString = try? String(jsonData) else { return }
        try? self.send(text: jsonString)
    }

    public func getMembers(ids: [String], guild: String) throws {
        guard req <= 30 else {
            print("blocked req")
            throw GatewayErrors.maxRequestReached
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
        guard let jsonData = try? JSONSerialization.data(withJSONObject: packet, options: []),
              let jsonString = try? String(jsonData) else { return }
        try? self.send(text: jsonString)
    }
}

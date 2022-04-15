//
//  Gateway.swift
//  Accord
//
//  Created by evelyn on 2022-01-01.
//

import AppKit // Necessary for the locale & architecture
import Combine
import Foundation
import Network

// The second version of Accord's gateway.
// This uses Network.framework instead of URLSessionWebSocketTask
final class Gateway {
    private(set) var connection: NWConnection?
    private(set) var sessionID: String?
    private(set) var interval: Int = 40000

    internal var pendingHeartbeat: Bool = false
    internal var heartbeatTimer: Cancellable?

    internal var seq: Int = 0
    internal var bag = Set<AnyCancellable>()

    // To communicate with the view
    private(set) var messageSubject = PassthroughSubject<(Data, String, Bool), Never>()
    private(set) var editSubject = PassthroughSubject<(Data, String), Never>()
    private(set) var deleteSubject = PassthroughSubject<(Data, String), Never>()
    private(set) var typingSubject = PassthroughSubject<(Data, String), Never>()
    private(set) var memberChunkSubject = PassthroughSubject<Data, Never>()
    private(set) var memberListSubject = PassthroughSubject<MemberListUpdate, Never>()

    private(set) var stateUpdateHandler: (NWConnection.State) -> Void = { state in
        switch state {
        case .ready:
            print("Ready up")
        case .cancelled:
            print("Connection cancelled, what happened?")
            wss.hardReset()
        case let .failed(error):
            print("Connection failed \(error.debugDescription)")
        case .preparing:
            print("Preparing")
        case let .waiting(error):
            print("Spinning infinitely \(error.debugDescription)")
        case .setup:
            print("Setting up")
        @unknown default:
            fatalError()
        }
    }

    private let socketEndpoint: NWEndpoint
    internal let compress: Bool

    public var cachedMemberRequest: [String: GuildMember] = [:]

    enum GatewayErrors: Error {
        case noStringData(String)
        case maxRequestReached
        case essentialEventFailed(String)
        case noSession
        case eventCorrupted
        case unknownEvent(String)
        case heartbeatMissed

        var localizedDescription: String {
            switch self {
            case let .essentialEventFailed(event):
                return "Essential Gateway Event failed: \(event)"
            case let .noStringData(string):
                return "Invalid data \(string)"
            case .maxRequestReached:
                return "Internal rate limit hit, you're going too fast!"
            case .noSession:
                return "Session missing?"
            case .eventCorrupted:
                return "Bad event sent"
            case let .unknownEvent(event):
                return "Unknown event: \(event)"
            case .heartbeatMissed:
                return "Heartbeat ACK missed"
            }
        }
    }

    private let additionalHeaders: [(String, String)] = [
        ("User-Agent", discordUserAgent),
        ("Pragma", "no-cache"),
        ("Origin", "https://discord.com"),
        ("Host", Gateway.gatewayURL.host ?? "gateway.discord.gg"),
        ("Accept-Language", "en-CA,en-US;q=0.9,en;q=0.8"),
        ("Accept-Encoding", "gzip, deflate, br"),
    ]

    static var gatewayURL: URL = .init(string: "wss://gateway.discord.gg?v=9&encoding=json")!
    
    internal var decompressor = ZStream()
    
    public init(
        url: URL = Gateway.gatewayURL,
        session_id: String? = nil,
        seq: Int? = nil,
        compress: Bool = true
    ) throws {
        if compress {
            socketEndpoint = NWEndpoint.url(URL(string: "wss://gateway.discord.gg?v=9&encoding=json&compress=zlib-stream")!)
            print(socketEndpoint)
        } else {
            socketEndpoint = NWEndpoint.url(url)
        }
        let parameters: NWParameters = .tls
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        wsOptions.maximumMessageSize = 1_000_000_000
        wsOptions.setAdditionalHeaders(additionalHeaders)
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
        connection = NWConnection(to: socketEndpoint, using: parameters)
        connection?.stateUpdateHandler = stateUpdateHandler
        self.compress = compress
        try connect(session_id, seq)
    }

    private func connect(_ session_id: String? = nil, _ seq: Int? = nil) throws {
        connection?.start(queue: concurrentQueue)
        hello(session_id, seq)
    }

    private func hello(_ session_id: String? = nil, _ seq: Int? = nil) {
        guard connection?.state != .cancelled else { return } // Don't listen for hello if there is no connection
        connection?.receiveMessage { [weak self] data, _, _, error in
            if let error = error {
                return print(error)
            }
            
            guard let data = data,
                  let decompressedData = try? self?.decompressor.decompress(data: data),
                  let hello = try? JSONSerialization.jsonObject(with: decompressedData, options: []) as? [String: Any],
                  let helloD = hello["d"] as? [String: Any],
                  let interval = helloD["heartbeat_interval"] as? Int else {
                print("Failed to get a heartbeat interval")
                return wss.hardReset()
            }
            self?.interval = interval
            DispatchQueue.main.async {
                self?.heartbeatTimer = Timer.publish(
                    every: Double(interval / 1000),
                    tolerance: nil,
                    on: .main,
                    in: .default
                )
                .autoconnect()
                .sink { [weak self] _ in
                    wssThread.async {
                        do {
                            print("Heartbeating")
                            try self?.heartbeat()
                        } catch {
                            print("Error sending heartbeat", error)
                        }
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

    private func listen(repeat _: Bool = true) {
        guard connection?.state != .cancelled else { return }
        connection?.receiveMessage { data, context, _, error in
            if let error = error {
                print(error)
            } else {
                self.listen()
            }
            guard let data = data else {
                return print(context as Any, data as Any)
            }
            if self.compress {
                self.decompressor.decompressionQueue.async {
                    guard let data = try? self.decompressor.decompress(data: data) else { return }
                    wssThread.async {
                        do {
                            let event = try GatewayEvent(data: data)
                            try self.handleMessage(event: event)
                        } catch { print(error) }
                    }
                }
            } else {
                wssThread.async {
                    do {
                        let event = try GatewayEvent(data: data)
                        try self.handleMessage(event: event)
                    } catch {
                        print(error)
                    }
                }
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
                "client_state": [
                    "guild_hashes": [:],
                    "highest_last_message_id": "0",
                    "read_state_version": 0,
                    "user_guild_settings_version": -1,
                    "user_settings_version": -1,
                ],
                "presence": [
                    "activities": [],
                    "afk": false,
                    "since": 0,
                    "status": "online",
                ],
                "properties": [
                    "os": "Mac OS X",
                    "browser": "Discord Client",
                    "release_channel": "stable",
                    "client_build_number": dscVersion,
                    "client_version": "0.0.266",
                    "os_version": NSWorkspace.shared.kernelVersion,
                    "os_arch": "x64",
                    "system-locale": "\(NSLocale.current.languageCode ?? "en")-\(NSLocale.current.regionCode ?? "US")",
                ],
            ],
        ]
        try send(json: packet)
    }

    private func heartbeat() throws {
        guard !pendingHeartbeat else {
            return AccordApp.error(GatewayErrors.heartbeatMissed, additionalDescription: "Check your network connection")
        }
        let packet: [String: Any] = [
            "op": 1,
            "d": seq,
        ]
        try send(json: packet)
        pendingHeartbeat = true
    }

    public func ready() -> Future<GatewayD, Error> {
        Future { [weak self] promise in
            self?.connection?.receiveMessage { data, context, _, error in
                if let error = error {
                    print(error)
                }
                guard let info = context?.protocolMetadata.first as? NWProtocolWebSocket.Metadata,
                      let data = data
                else {
                    return AccordApp.error(GatewayErrors.essentialEventFailed("READY"), additionalDescription: "Try reconnecting?")
                }
                switch info.opcode {
                case .text:
                    wssThread.async {
                        do {
                            try wss.updateVoiceState(guildID: nil, channelID: nil)
                            let path = FileManager.default.urls(for: .cachesDirectory,
                                                                in: .userDomainMask)[0]
                                .appendingPathComponent("socketOut.json")
                            try data.write(to: path)
                            let structure = try JSONDecoder().decode(GatewayStructure.self, from: data)
                            wssThread.async {
                                self?.listen()
                            }
                            print("Hello, \(structure.d.user.username)#\(structure.d.user.discriminator) !!")
                            self?.sessionID = structure.d.session_id
                            print("Connected with session ID", structure.d.session_id)
                            promise(.success(structure.d))
                            return
                        } catch {
                            promise(.failure(error))
                            AccordApp.error(error)
                            return
                        }
                    }
                case .close:
                    if let closeMessage = String(data: data, encoding: .utf8) {
                        print("Closed with #\(closeMessage)#")
                        switch closeMessage {
                        case "Authentication failed.":
                            logOut()
                            NSApplication.shared.restart()
                        default: break
                        }
                    } else {
                        print("Closed with unknown close code")
                    }
                case .cont: break
                case .binary:
                    print("binary packet")
                    self?.decompressor.decompressionQueue.async {
                        guard let data = try? self?.decompressor.decompress(data: data, large: true) else { return }
                        wssThread.async {
                            do {
                                try wss.updateVoiceState(guildID: nil, channelID: nil)
                                let path = FileManager.default.urls(for: .cachesDirectory,
                                                                    in: .userDomainMask)[0]
                                    .appendingPathComponent("socketOut.json")
                                try data.write(to: path)
                                let structure = try JSONDecoder().decode(GatewayStructure.self, from: data)
                                wssThread.async {
                                    self?.listen()
                                }
                                print("Hello, \(structure.d.user.username)#\(structure.d.user.discriminator) !!")
                                self?.sessionID = structure.d.session_id
                                print("Connected with session ID", structure.d.session_id)
                                promise(.success(structure.d))
                                return
                            } catch {
                                promise(.failure(error))
                                AccordApp.error(error)
                                return
                            }
                        }
                    }
                case .ping: print("ping")
                case .pong: print("pong")
                @unknown default:
                    break
                }
            }
        }
    }

    public func updatePresence(status: String, since: Int, @ActivityBuilder _ activities: () -> [Activity]) throws {
        let packet: [String: Any] = [
            "op": 3,
            "d": [
                "status": status,
                "since": since,
                "activities": activities().map(\.dictValue),
                "afk": false,
            ],
        ]
        try send(json: packet)
    }

    public func reconnect(session_id: String? = nil, seq: Int? = nil) throws {
        let packet: [String: Any] = [
            "op": 6,
            "d": [
                "seq": seq ?? self.seq,
                "session_id": session_id ?? sessionID ?? "",
                "token": AccordCoreVars.token,
            ],
        ]
        try send(json: packet)
        wssThread.async {
            self.listen()
        }
    }

    public func subscribe(to guild: String) throws {
        let packet: [String: Any] = [
            "op": 14,
            "d": [
                "guild_id": guild,
                "typing": true,
                "activities": true,
                "threads": true,
            ],
        ]
        try send(json: packet)
    }

    public func memberList(for guild: String, in channel: String) throws {
        let packet: [String: Any] = [
            "op": 14,
            "d": [
                "channels": [
                    channel: [[
                        0, 99,
                    ]],
                ],
                "guild_id": guild,
            ],
        ]
        try send(json: packet)
    }

    public func subscribeToDM(_ channel: String) throws {
        let packet: [String: Any] = [
            "op": 13,
            "d": [
                "channel_id": channel,
            ],
        ]
        try send(json: packet)
        print("sent packet")
    }

    public func getMembers(ids: [String], guild: String) throws {
        let packet: [String: Any] = [
            "op": 8,
            "d": [
                "limit": 0,
                "user_ids": ids,
                "guild_id": guild,
            ],
        ]
        try send(json: packet)
    }

    public func getCommands(guildID: String, commandIDs: [String] = [], limit: Int = 10) throws {
        let packet: [String: Any] = [
            "op": 24,
            "d": [
                "applications": true,
                "command_ids": commandIDs,
                "guild_id": guildID,
                "limit": limit,
                "locale": NSNull(),
                "nonce": generateFakeNonce(),
                "offset": 0,
                "type": 1,
            ],
        ]
        try send(json: packet)
    }

    public func getCommands(guildID: String, query: String, limit: Int = 10) throws {
        let packet: [String: Any] = [
            "op": 24,
            "d": [
                "locale": NSNull(),
                "query": query,
                "guild_id": guildID,
                "limit": limit,
                "nonce": generateFakeNonce(),
                "type": 1,
            ],
        ]
        try send(json: packet)
    }

    // cleanup
    deinit {
        self.heartbeatTimer = nil
        self.bag.invalidateAll()
    }
}

@resultBuilder
enum ActivityBuilder {
    static func buildBlock() -> [Activity] { [] }
}

extension ActivityBuilder {
    static func buildBlock(_ activities: Activity...) -> [Activity] {
        activities
    }
}

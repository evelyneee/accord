//
//  RTCSocket.swift
//  Accord
//
//  Created by evelyn on 2022-06-02.
//

import Combine
import Foundation

final class RTCSocket {
    let ws: URLSessionWebSocketTask
    let guildID: String?
    let channelID: String
    var token: String

    private(set) var seq: Int = 0
    private(set) var interval: Int = 0
    private(set) var timer: Cancellable?

    init(
        url: URL?,
        token: String,
        guildID: String? = nil,
        channelID: String
    ) throws {
        guard let url = url else {
            throw "Bad RTC socket url"
        }
        self.token = token
        self.guildID = guildID
        self.channelID = channelID
        let request = URLRequest(url: url)
        let task = URLSession.shared.webSocketTask(with: request)
        ws = task
        try listen()
        ws.resume()
        try identify()
    }

    func identify() throws {
        let packet: [String: Any] = [
            "op": 0,
            "d": [
                "server_id": guildID as Any,
                "user_id": user_id,
                "session_id": wss.sessionID ?? "",
                "token": token,
                "video": true,
                "streams": [
                    [
                        "type": "video", "rid": "100", "quality": 100,
                    ],
                    [
                        "type": "video", "rid": "50", "quality": 50,
                    ],
                ],
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: packet, options: [])
        let string = try String(data)
        print(string)
        let message = URLSessionWebSocketTask.Message.string(string)
        ws.send(message, completionHandler: { error in
            if let error = error {
                print(error)
            }
        })
    }

    func listen() throws {
        ws.receive {
            switch $0 {
            case let .success(message):
                print(message)
                switch message {
                case let .string(string):
                    guard let data = string.data(using: .utf8),
                          let packet = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let opcode = packet["op"] as? Int else { break }
                    switch Opcodes(rawValue: opcode) {
                    case .`init`:
                        break
                    case .protocolUpdate:
                        break
                    case .ready:
                        print(packet)
                        try? self.success()
                    case .ping:
                        break
                    case .codecUpdate:
                        print(packet)
                    case .status:
                        print(packet)
                    case .pong:
                        self.seq = packet["d"] as? Int ?? self.seq
                    case .hello:
                        print(packet)
                        let d = packet["d"] as? [String: Any]
                        self.interval = d?["heartbeat_interval"] as? Int ?? 0
                        self.timer = Timer.publish(
                            every: Double(self.interval / 1000),
                            tolerance: nil,
                            on: .main,
                            in: .default
                        )
                        .autoconnect()
                        .sink { _ in
                            try? self.heartbeat()
                        }
                    case .typeUpdate:
                        break
                    case .versionUpdate:
                        break
                    case .none:
                        print("Unknown Voice Opcode", opcode)
                    }
                    try? self.listen()
                case .data: break
                @unknown default: break
                }
            case let .failure(error):
                print(error)
            }
        }
    }

    func heartbeat() throws {
        let packet: [String: Any] = [
            "op": 1,
            "d": seq,
        ]

        try sendMessage(packet)
    }

    func success() throws {
        let packet: [String: Any] = [
            "op": 16,
            "d": [],
        ]
        try sendMessage(packet)
    }

    func sendMessage<C: Collection>(_ packet: C) throws {
        let data = try JSONSerialization.data(withJSONObject: packet, options: [])
        let string = try String(data)
        print(string)
        let message = URLSessionWebSocketTask.Message.string(string)
        ws.send(message, completionHandler: { error in
            if let error = error {
                print(error)
            }
        })
    }
}

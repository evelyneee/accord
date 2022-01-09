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
    
    func send<S>(text: S) throws where S: Collection, S.Element == Character {
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
    
    func send<C: Collection>(json: C) throws {
        let context = NWConnection.ContentContext(
            identifier: "textContext",
            metadata: [NWProtocolWebSocket.Metadata(opcode: .text)]
        )
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        self.connection?.send(content: jsonData, contentContext: context, completion: .contentProcessed { error in
            if let error = error {
                print(error)
            }
        })
    }
    
    func send(data: Data) throws {
        let context = NWConnection.ContentContext(
            identifier: "binaryContext",
            metadata: [NWProtocolWebSocket.Metadata(opcode: .binary)]
        )
        self.connection?.send(content: data, contentContext: context, completion: .contentProcessed { error in
            if let error = error {
                print(error)
            }
        })
    }
    
    func reset(function: String = #function) {
        print("resetting from function", function)
        self.close(.protocolCode(.protocolError))
        concurrentQueue.async {
            guard let new = try? Gateway.init(url: Gateway.gatewayURL, session_id: wss.sessionID, seq: wss.seq) else { return }
            wss = new
        }
    }

    func hardReset(function: String = #function) {
        print("resetting from function", function)
        self.close(.protocolCode(.normalClosure))
        concurrentQueue.async {
            guard let new = try? Gateway.init(url: Gateway.gatewayURL) else { return }
            new.ready().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &new.bag)
            wss = new
        }
    }
    
    func decodePayload(payload: Data) -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any]
    }
}

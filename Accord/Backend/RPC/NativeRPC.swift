//
//  NativeRPC.swift
//  Accord
//
//  Created by evelyn on 2022-01-15.
//

import Foundation
import Combine
import Network

final class RPC {
    
    private (set) var listeners: [NWListener] = []
    
    init?(port: UInt16) {
        for i in 0..<10 {
            let parameters = NWParameters(tls: nil)
            parameters.allowLocalEndpointReuse = true
            parameters.includePeerToPeer = true
            let wsOptions = NWProtocolWebSocket.Options()
            wsOptions.autoReplyPing = true
            parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
            let port = NWEndpoint.Port.init(rawValue: 6462 + UInt16(i))!
            guard let listener = try? NWListener(using: parameters, on: port) else {
                return nil
            }
            listener.newConnectionHandler = { connection in
                print(connection)
                func handle() {
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, context, isComplete, error in
                        if let data = data {
                            print(String(data: data, encoding: .utf8))
                        } else {
                            connection.cancel()
                        }
                        handle()
                    }
                }
                connection.start(queue: .main)
                handle()
            }
            listener.start(queue: .main)
            self.listeners.append(listener)
        }
    }
}

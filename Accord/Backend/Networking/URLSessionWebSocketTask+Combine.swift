//
//  URLSessionWebSocketTask+Combine.swift
//  Accord
//
//  Created by evelyn on 2021-12-17.
//

import Foundation
import Combine

extension URLSessionWebSocketTask {
    func receivePublisher() -> Future<URLSessionWebSocketTask.Message, Error> {
        Future { promise in
            self.receive { c in
                switch c {
                case .success(let msg):
                    promise(.success(msg))
                case .failure(let err):
                    promise(.failure(err))
                }
            }
        }
    }
    func sendPingPublisher() -> Future<Never, Error> {
        Future { promise in
            self.sendPing { err in
                if let err = err {
                    promise(.failure(err))
                }
            }
        }
    }
    func sendPublisher(_ message: Message) -> Future<Never, Error> {
        Future { promise in
            self.send(message, completionHandler: { err in
                if let err = err {
                    promise(.failure(err))
                }
            })
        }
    }
}

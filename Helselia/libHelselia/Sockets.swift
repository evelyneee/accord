//
//  Sockets.swift
//  Helselia
//
//  Created by evelyn on 2021-06-05.
//

import Foundation

final class WebSocketHandler {
    static var shared = WebSocketHandler()
    func newMessage(opcode: Int, item: String, _ completion: @escaping ((_ success: Bool, _ array: [[String:Any]]?) -> Void)) {
        let webSocketDelegate = WebSocket()
        let session = URLSession(configuration: .default, delegate: webSocketDelegate, delegateQueue: OperationQueue())
        let url = URL(string: "wss://gateway.constanze.live")!
        let webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
        send()
        ping()
        _ = checkConnection() {success, array in print(array)}
        func send() {
            let packet: [String : Any] = ["op":2, "d":["token":token, "properties": ["os":"macOS", "browser":"", "device":""]]]
            let jsonPacket = try! JSONSerialization.data(withJSONObject: packet, options: [])
            let message = URLSessionWebSocketTask.Message.data(jsonPacket)
            webSocketTask.send(message) { error in
                print("sent", message)
                if let error = error {
                    print("WebSocket sending error: \(error)")
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
        func receive() -> String {
            let rettext = ""
            webSocketTask.receive { result in
                switch result {
                    case .success(let message):
                        switch message {
                        case .data(let data):
                            print("Data received \(data)")
                        case .string(let text):
                            print("Text received \(text)")
                        @unknown default:
                            print("unknown")
                        }
                case .failure(let error):
                    print("Error when receiving \(error)")
                }
            }
            return rettext
        }
        func close() {
            let reason = "Closing connection".data(using: .utf8)
            webSocketTask.cancel(with: .goingAway, reason: reason)
        }
        func checkConnection(_ completion: @escaping ((_ success: Bool, _ array: [[String:Any]]?) -> Void)) {
            var retValue: Bool = false {
                didSet {
                    print("set that \(retValue)")
                }
            }
            var _: Bool = false
            var retDict: [[String:Any]] = []
            webSocketTask.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data):
                        print("Data received \(data)")
                        retValue = false
                    case .string(let text):
                        print(text)
                        if let data = text.data(using: String.Encoding.utf8) {
                            do {
                                let tempretDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] ?? [:]
                                retDict = ((tempretDict["d"] as? [String:Any] ?? [:])["clubs"] as? [[String:Any]]) ?? []
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
            print(retDict)
            return completion(false, nil)
        }

        checkConnection() { success, array in
            if success {
                return completion(true, array)
            }
        }
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

class WebSocket: NSObject, URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
    }
}

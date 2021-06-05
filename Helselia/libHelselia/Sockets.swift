//
//  Sockets.swift
//  Helselia
//
//  Created by evelyn on 2021-06-05.
//

import Foundation

final class WebSocketHandler {
    static var shared = WebSocketHandler()
    func newMessage(opcode: Int) -> [String:Any] {
        let webSocketDelegate = WebSocket()
        let session = URLSession(configuration: .default, delegate: webSocketDelegate, delegateQueue: OperationQueue())
        let url = URL(string: "wss://gateway.constanze.live")!
        let webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
        send()
        ping()
        receive()
        func send() {
            do {
                let packet: [String : Any] = ["op":2, "d":["token":token, "properties": ["os":"macOS", "browser":"", "device":""]]]
                let jsonPacket = try! JSONSerialization.data(withJSONObject: packet, options: [])
                let message = URLSessionWebSocketTask.Message.data(jsonPacket)
                webSocketTask.send(message) { error in
                    print("sent", message)
                    if let error = error {
                        print("WebSocket sending error: \(error)")
                    }
                }
            } catch {
            }
        }
        func ping() {
          webSocketTask.sendPing { error in
            if let error = error {
              print("Error when sending PING \(error)")
            } else {
                print("Web Socket connection is alive")
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    ping()
                }
            }
          }
        }
        func receive() -> String {
            var rettext = ""
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
                    print("Error when receiving")
                }
            }
            return rettext
        }
        func close() {
            let reason = "Closing connection".data(using: .utf8)
            webSocketTask.cancel(with: .goingAway, reason: reason)
        }
        func checkConnection() -> [String:Any] {
            var retValue: Bool = false {
                didSet {
                    print("set that \(retValue)")
                }
            }
            var completion: Bool = false
            var retDict: [String:Any] = [:]
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
                                retDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] ?? [:]
                                print((retDict["d"] as? [String:Any] ?? [:])["clubs"])
                            } catch let error as NSError {
                                print(error)
                            }
                        }
                    @unknown default:
                        print("unknown")
                        retValue = false
                    }
                case .failure(let error):
                    print("Error when receiving")
                    retValue = false
                }
            }
            return retDict
        }
        return checkConnection()
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

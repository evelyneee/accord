//
//  NetworkHandler.swift
//  Helselia
//
//  Created by evelyn on 2021-02-27.
//


import Foundation

let debug = true

struct socketPayload {
    var op: Int
    struct d {
        var os: String
        var browser: String
        var type: String
    }
}

public class NetworkHandling {
    func request(url: String, token: String, Cookie: String, json: Bool, type: requests.requestTypes, bodyObject: [String:Any]) -> [[String:Any]] {
        let group = DispatchGroup()
        var completion: Bool = false
        var tries: Int = 0
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)
        var retData: Data = Data()
        switch type {
        case .GET:
            request.httpMethod = "GET"
        case .POST:
            request.httpMethod = "POST"
        case .PATCH:
            request.httpMethod = "PATCH"
        case .DELETE:
            request.httpMethod = "DELETE"
        case .PUT:
            request.httpMethod = "PUT"
        }
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(Cookie, forHTTPHeaderField: "Cookie")
        if type == .POST {
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }
        var returnArray: [[String:Any]] = []
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                print("success \(Date())")
                let statusCode = (response as! HTTPURLResponse).statusCode
                retData = Data(data!)
                if data != Data() {
                    do {
                        returnArray = try JSONSerialization.jsonObject(with: data ?? Data(), options: .mutableContainers) as? [[String:Any]] ?? [[String:Any]]()
                    } catch {
                        print("error at serializing: \(error.localizedDescription)")
                    }
                } else {
                    returnArray = [["Code":statusCode]]
                }
                if debug {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                }
            }
            else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        if type == .GET {
            print("starting \(Date())")
            while completion == false {
                task.resume()
                session.finishTasksAndInvalidate()
                if retData != Data() {
                    print("none yet : \(Date())")
                    do {
                        returnArray = try JSONSerialization.jsonObject(with: retData, options: .mutableContainers) as? [[String:Any]] ?? [[String:Any]]()
                    } catch {
                        print("error at serializing: \(error.localizedDescription)")
                    }
                    completion = true
                    print("returned properly \(Date())")
                    return returnArray
                }
            }
        } else {
            task.resume()
            session.finishTasksAndInvalidate()
            sleep(1)
            return returnArray
        }
    }
    func checkConnection() -> Bool {
        var ret: Bool = false
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: "https://constanze.live/api/v1/auth/login") ?? URL(string: "#"))!)
        request.httpMethod = "POST"
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                // Success
                ret = true
                print("URL Session Task Succeeded: HTTP \(statusCode)")
            }
            else {
                // Failure
                ret = false
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
        return ret
    }
}

class WebSocket: NSObject, URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
    }
}

public class WebSocketHandler {
    func newMessage() -> Bool {
        let webSocketDelegate = WebSocket()
        let session = URLSession(configuration: .default, delegate: webSocketDelegate, delegateQueue: OperationQueue())
        let url = URL(string: "wss://gateway.constanze.live")!
        let webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
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
        func checkConnection() -> Bool {
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
                                for item in retDict.keys {
                                    if item == "t" {
                                        if let _ = retDict["t"] as? NSNull {
                                            retValue = false
                                            completion = true
                                        } else {
                                            retValue = true
                                            completion = true
                                        }
                                        print(type(of: retDict["t"]))
                                    }
                                }
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
            while completion == false {
                if completion == true {
                    return retValue
                } else {
                    sleep(0)
                }
            }
            return retValue
        }
        return checkConnection()
    }
}

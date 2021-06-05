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

final class NetworkHandling {
    static var shared = NetworkHandling()
    func request(url: String, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any], _ completion: @escaping ((_ success: Bool, _ array: [[String:Any]]?) -> Void)) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)
        var retData: Data?
        
        // setup of the request
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
        
        // helselia specific stuff starts here
        
        if token != nil {
            request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        }
        if json == false && type == .POST {
            let bodyString = (bodyObject as? [String:String] ?? [:]).queryParameters
            request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if type == .POST && json == true {
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }
        var returnArray: [[String:Any]] = []
        
        // ends here
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if (error == nil) {
                // Success
                print("success \(Date())")
                let statusCode = (response as! HTTPURLResponse).statusCode
                if let data = data {
                    do {
                        returnArray = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String:Any]] ?? [[String:Any]]()
                        return completion(true, returnArray)
                    } catch {
                        print("error at serializing: \(error.localizedDescription)")
                        return
                    }
                } else {
                    returnArray = [["Code":statusCode]]
                }
                if debug {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields)
                    print(request.url)
                    print(bodyObject)
                }
            }
            else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        return completion(false, nil)
    }
    func requestData(url: String, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any], _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)
        var retData: Data?
        
        // setup of the request
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
        
        // helselia specific stuff starts here
        
        if token != nil {
            request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        }
        if json == false && type == .POST {
            let bodyString = (bodyObject as? [String:String] ?? [:]).queryParameters
            request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if type == .POST && json == true {
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }        
        // ends here
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if (error == nil) {
                // Success
                print("success \(Date())")
                let statusCode = (response as! HTTPURLResponse).statusCode
                if let data = data {
                    do {
                        print(data, "deez")
                        return completion(true, data)
                    } catch {
                        print("error at serializing: \(error.localizedDescription)")
                        return
                    }
                } else {
                }
                if debug {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields)
                    print(request.url)
                    print(bodyObject)
                }
            }
            else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        return completion(false, nil)
    }
    func login(username: String, password: String, _ completion: @escaping ((_ success: Bool, _ rettoken: String?) -> Void)) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: "https://constanze.live/api/v1/auth/login") ?? URL(string: "#")!))
        var retData: Data?
        
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // Form URL-Encoded Body
        let bodyObject: [String : Any] = [
            "email": username,
            "password": password
        ]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        var token: String = ""
        
        // ends here
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                print("success \(Date())")
                let statusCode = (response as! HTTPURLResponse).statusCode
                if data != Data() {
                    do {
                        let returnArray = try JSONSerialization.jsonObject(with: data ?? Data(), options: .mutableContainers) as? [String:Any] ?? [String:Any]()
                        print(returnArray)
                        if let checktoken = returnArray["token"] as? String {
                            return completion(true, checktoken)
                        }
                    } catch {
                        print("error at serializing: \(error.localizedDescription)")
                    }
                } else {
                }
                if debug {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields)
                    print(request.httpBody)
                }
            }
            else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        return completion(false, nil)
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

final class WebSocketHandler {
    static var shared = WebSocketHandler()
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

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
    
}

extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}


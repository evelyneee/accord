//
//  NetworkHandler.swift
//  Accord
//
//  Created by evelyn on 2021-02-27.
//

import Foundation

let debug = false

final class NetworkHandling {
    static var shared: NetworkHandling = NetworkHandling()

    final func request(url: String, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any], _ completion: @escaping ((_ success: Bool, _ array: [[String:Any]]?) -> Void)) {
        let config = URLSessionConfiguration.default
        if proxyEnabled {
            config.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            config.connectionProxyDictionary = [AnyHashable: Any]()
            config.connectionProxyDictionary?[kCFNetworkProxiesHTTPEnable as String] = 1
            if let ip = proxyIP {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPProxy as String] = ip
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSProxy as String] = ip
            }
            if let port = proxyPort {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPPort as String] = Int(port)
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSPort as String] = Int(port)
            }
        }
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)

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

        // discord specific stuff

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
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }

        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                if debug {
                    print("[Accord] URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields as Any)
                    print(request.url as Any)
                }
                if let data = data {
                    do {
                        return completion(true, try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] ?? [[String:Any]]())
                    } catch {
                        print("[Accord] error at serializing: \(error.localizedDescription)")
                        return completion(false, nil)
                    }
                } else {
                    return completion(false, nil)
                }

            }
            else {
                return completion(false, nil)
            }
        })
        task.resume()
    }
    final func requestData(url: String, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any], _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
        let config = URLSessionConfiguration.default
        if proxyEnabled {
            config.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            config.connectionProxyDictionary = [AnyHashable: Any]()
            config.connectionProxyDictionary?[kCFNetworkProxiesHTTPEnable as String] = 1
            if let ip = proxyIP {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPProxy as String] = ip
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSProxy as String] = ip
            }
            if let port = proxyPort {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPPort as String] = Int(port)
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSPort as String] = Int(port)
            }
        }
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)

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

        // Accord specific stuff starts here

        if token != nil {
            request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        }
        if json == false && type == .POST {
            let bodyString = (bodyObject as? [String:String] ?? [:]).queryParameters
            request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if type == .POST && json == true {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }

        session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if (error == nil) {
                // Success
                if debug {
                    let statusCode = (response as! HTTPURLResponse).statusCode
                    print("[Accord] URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields as Any)
                    print(request.url as Any)
                }
                if let data = data {
                    return completion(true, data)
                } else {
                    return completion(false, nil)
                }

            }
            else {
                print("[Accord] URL Session Task Failed: %@", error!.localizedDescription);
                return completion(false, nil)
            }
        }).resume()
    }
    func emptyRequest(url: String, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any]) {
        let config = URLSessionConfiguration.default
        if proxyEnabled {
            config.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            config.connectionProxyDictionary = [AnyHashable: Any]()
            config.connectionProxyDictionary?[kCFNetworkProxiesHTTPEnable as String] = 1
            if let ip = proxyIP {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPProxy as String] = ip
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSProxy as String] = ip
            }
            if let port = proxyPort {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPPort as String] = Int(port)
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSPort as String] = Int(port)
            }
        }
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)

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

        // Accord specific stuff starts here

        if token != nil {
            request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        }
        if json == false && type == .POST {
            let bodyString = (bodyObject as? [String:String] ?? [:]).queryParameters
            request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if type == .POST && json == true {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }

        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if (error == nil) && (data != nil) {
                return
            } else {
                print("[Accord] URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
    }

    final func login(username: String, password: String, captcha: String = "", _ completion: @escaping ((_ success: Bool, _ rettoken: Data?) -> Void)) {
        let config = URLSessionConfiguration.default
        if proxyEnabled {
            config.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            config.connectionProxyDictionary = [AnyHashable: Any]()
            config.connectionProxyDictionary?[kCFNetworkProxiesHTTPEnable as String] = 1
            if let ip = proxyIP {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPProxy as String] = ip
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSProxy as String] = ip
            }
            if let port = proxyPort {
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPPort as String] = Int(port)
                config.connectionProxyDictionary?[kCFNetworkProxiesHTTPSPort as String] = Int(port)
            }
        }
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: "https://discord.com/api/v9/auth/login") ?? URL(string: "#")!))

        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        if captcha == "" {
            let bodyObject: [String : Any] = [
                "email": username,
                "password": password,
                "undelete": false
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyObject, options: [])
        } else {
            let bodyObject: [String : Any] = [
                "email": username,
                "password": password,
                "captcha_key": captcha,
                "undelete": false
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }

        session.dataTask(with: request, completionHandler: { (data, response, error) in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                if debug {
                    print("[Accord] URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields as Any)
                    print(request.httpBody as Any)
                }
                if data != Data() {
                    return completion(true, data)
                } else {
                    return completion(false, nil)
                }
            } else {
                print("[Accord] URL Session Task Failed: %@", error!.localizedDescription);
            }
        }).resume()
    }
}

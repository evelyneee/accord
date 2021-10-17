//
//  NetworkHandler.swift
//  Accord
//
//  Created by evelyn on 2021-02-27.
//

import Foundation
import Combine
import AppKit

let debug = false

@available(*, deprecated)
final class NetworkHandling {
    static var shared: NetworkHandling = NetworkHandling()
    final func cachedRequestData(url: String, referer: String? = nil, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any], _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {

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
        config.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) discord/0.0.276 Chrome/91.0.4472.164 Electron/13.2.2 Safari/537.36"]
        config.requestCachePolicy = URLRequest.CachePolicy.returnCacheDataElseLoad
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
        if (type == .POST || type == .PUT || type == .PATCH || type == .DELETE) && json == true {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }
        request.timeoutInterval = 30.0
        session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                // Success
                if debug {
                    let statusCode = (response as! HTTPURLResponse).statusCode
                    print("[Accord] URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields as Any)
                    print(request.url as Any)
                }
                return completion(true, data)
            } else {
                print("[Accord] URL Session Task Failed: %@", String(describing: error));
                return completion(false, nil)
            }
        }).resume()
    }

    final func requestData(url: String, referer: String? = nil, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any], _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
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
        config.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) discord/0.0.276 Chrome/91.0.4472.164 Electron/13.2.2 Safari/537.36"]
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
        } else {
            request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if type == .POST && json == true {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }
        request.timeoutInterval = 30.0
        // Necessary headers
        request.addValue("discord.com", forHTTPHeaderField: ":authority")
//        request.addValue(request.httpMethod ?? "", forHTTPHeaderField: ":method")
//        request.addValue("https", forHTTPHeaderField: ":scheme")
//        request.addValue(String(url.replacingOccurrences(of: "https://discord.com", with: "")), forHTTPHeaderField: ":path")
        if let referer = referer {
            request.addValue(referer, forHTTPHeaderField: "referer")
        }
        request.addValue("empty", forHTTPHeaderField: "sec-fetch-dest")
        request.addValue("cors", forHTTPHeaderField: "sec-fetch-mode")
        request.addValue("user-agent", forHTTPHeaderField: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) discord/0.0.276 Chrome/91.0.4472.164 Electron/13.2.2 Safari/537.36")

        defer {
            session.finishTasksAndInvalidate()
        }
        session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                // Success
                if debug {
                    let statusCode = (response as! HTTPURLResponse).statusCode
                    print("[Accord] URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields as Any)
                    print(request.url as Any)
                }
                return completion(true, data)
            } else {
                print("[Accord] URL Session Task Failed: %@", String(describing: error));
                return completion(false, nil)
            }
        }).resume()
    }
    func emptyRequest(url: String, referer: String? = nil, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any]) {
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
        config.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) discord/0.0.276 Chrome/91.0.4472.164 Electron/13.2.2 Safari/537.36"]
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
        
        // Necessary headers
        request.addValue("discord.com", forHTTPHeaderField: ":authority")
//        request.addValue(request.httpMethod ?? "GET", forHTTPHeaderField: ":method")
//        request.addValue("https", forHTTPHeaderField: ":scheme")
//        request.addValue(String(url.replacingOccurrences(of: "https://discord.com", with: "")), forHTTPHeaderField: ":path")
        if let referer = referer {
            request.addValue(referer, forHTTPHeaderField: "referer")
        }
        request.addValue("empty", forHTTPHeaderField: "sec-fetch-dest")
        request.addValue("cors", forHTTPHeaderField: "sec-fetch-mode")
        request.addValue("user-agent", forHTTPHeaderField: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) discord/0.0.276 Chrome/91.0.4472.164 Electron/13.2.2 Safari/537.36")
        defer {
            session.finishTasksAndInvalidate()
        }
        session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if (error == nil) && (data != nil) {
                return
            } else {
                print("[Accord] URL Session Task Failed: %@", error!.localizedDescription);
            }
        }).resume()
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
                if let data = data {
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

public enum RequestTypes: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

final class Headers {
    init(userAgent: String? = nil, contentType: String? = nil, token: String? = nil, bodyObject: [String:String]? = nil, type: RequestTypes, discordHeaders: Bool = false, referer: String? = nil) {
        self.userAgent = userAgent
        self.contentType = contentType
        self.token = token
        self.bodyObject = bodyObject
        self.type = type
        self.discordHeaders = discordHeaders
        self.referer = referer
    }
    var userAgent: String?
    var contentType: String?
    var token: String?
    var bodyObject: [String:String]?
    var type: RequestTypes
    var discordHeaders: Bool
    var referer: String?
}


final class Networking<T: Decodable> {
    typealias completionBlock = ((_ value: Optional<T>) -> Void)
    typealias imgBlock = ((_ value: Optional<NSImage>) -> Void)
    func fetch(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping completionBlock) {
        guard request != nil || url != nil else {
            fatalError("You need to provide a request method")
        }
        
        var request = request ?? URLRequest(url: url!)
        let config = URLSessionConfiguration.default
        
        // Set headers from headers object
        if let headers = headers {
            if let userAgent = headers.userAgent {
                config.httpAdditionalHeaders = ["User-Agent": userAgent]
            }
            if let contentType = headers.contentType {
                request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            }
            if let token = headers.token {
                request.addValue("\(token)", forHTTPHeaderField: "Authorization")
            }
            if let bodyObject = headers.bodyObject {
                let bodyString = bodyObject.queryParameters
                request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            }
            if headers.discordHeaders {
                request.addValue("discord.com", forHTTPHeaderField: ":authority")
                request.addValue("empty", forHTTPHeaderField: "sec-fetch-dest")
                request.addValue("cors", forHTTPHeaderField: "sec-fetch-mode")
                request.addValue("user-agent", forHTTPHeaderField: headers.userAgent ?? "WebKit")
            }
            if let referer = headers.referer {
                request.addValue(referer, forHTTPHeaderField: "referer")
            }
            request.httpMethod = headers.type.rawValue
        }
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data {
                guard error == nil else {
                    print(error?.localizedDescription ?? "")
                    return completion(nil)
                }
                guard let value = try? JSONDecoder().decode(T.self, from: data) else { return completion(nil) }
                return completion(value)
            }
        }).resume()
    }
    func image(url: URL?, to size: CGSize? = nil, completion: @escaping imgBlock) {
        let request = URLRequest(url: url!)
        if let cachedImage = cache.cachedResponse(for: request) {
            return completion(NSImage(data: cachedImage.data) ?? NSImage())
        }
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard error == nil,
              let data = data,
                let imageData = NSImage(data: data)?.downsample(to: size ?? CGSize(width: 600, height: 600)),
                    let image = NSImage(data: imageData) else {
                      print(error?.localizedDescription ?? "")
                      return completion(nil)
            }
            cache.storeCachedResponse(CachedURLResponse(response: response!, data: imageData), for: request)
            return completion(image)
        }).resume()
    }
}

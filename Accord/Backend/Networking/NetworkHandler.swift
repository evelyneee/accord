//
//  NetworkHandler.swift
//  Accord
//
//  Created by evelyn on 2021-02-27.
//

import Foundation
import Combine
import AppKit

public enum RequestTypes: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

final class Headers {
    init(userAgent: String? = nil, contentType: String? = nil, token: String? = nil, bodyObject: [String:Any]? = nil, type: RequestTypes, discordHeaders: Bool = false, referer: String? = nil, empty: Bool = false, json: Bool = false) {
        self.userAgent = userAgent
        self.contentType = contentType
        self.token = token
        self.bodyObject = bodyObject
        self.type = type
        self.discordHeaders = discordHeaders
        self.referer = referer
        self.empty = empty
        self.json = json
    }
    var userAgent: String?
    var contentType: String?
    var token: String?
    var bodyObject: [String:Any]?
    var type: RequestTypes
    var discordHeaders: Bool
    var referer: String?
    var empty: Bool?
    var json: Bool
    func set(request: inout URLRequest, config: inout URLSessionConfiguration) {
        if let userAgent = self.userAgent {
            config.httpAdditionalHeaders = ["User-Agent": userAgent]
        }
        if let contentType = self.contentType, !(self.json) {
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if let token = self.token {
            request.addValue(token, forHTTPHeaderField: "Authorization")
        }
        if self.json {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: self.bodyObject ?? [:], options: [])
        } else if let bodyObject = self.bodyObject {
            let bodyString = bodyObject.queryParameters
            request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
        }
        if self.discordHeaders {
            request.addValue("discord.com", forHTTPHeaderField: ":authority")
            request.addValue("https://discord.com", forHTTPHeaderField: "origin")
            request.addValue("empty", forHTTPHeaderField: "sec-fetch-dest")
            request.addValue("cors", forHTTPHeaderField: "sec-fetch-mode")
            request.addValue("same-origin", forHTTPHeaderField: "sec-fetch-site")
            request.addValue(self.userAgent ?? "WebKit", forHTTPHeaderField: "user-agent")
        }
        if let referer = self.referer {
            request.addValue(referer, forHTTPHeaderField: "referer")
        }

        request.httpMethod = self.type.rawValue
    }
}

var standardHeaders = Headers(userAgent: discordUserAgent, contentType: nil, token: AccordCoreVars.shared.token, type: .GET, discordHeaders: true)

final class Request {
    
    // MARK: - Empty Decodable
    struct AnyDecodable: Decodable { }
    
    // MARK: - Perform request with completion handler
    final public class func fetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping ((_ value: Optional<T>) -> Void)) -> Void {
        
        let request: URLRequest? = {
            if let request = request {
                return request
            } else if let url = url {
                return URLRequest(url: url)
            } else {
                print("[Networking] You need to provide a request method")
                return nil
            }
        }()
        guard var request = request else { return completion(nil) }
        var config = URLSessionConfiguration.default
        
        // Set headers
        headers?.set(request: &request, config: &config)
        
        URLSession(configuration: config).dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data {
                guard error == nil else {
                    print(error?.localizedDescription ?? "unknown error")
                    return completion(nil)
                }
                if T.self == AnyDecodable.self || headers?.empty ?? false {
                    return completion(nil) // Bail out if we don't ask for a type
                }
                let value = try? JSONDecoder().decode(T.self, from: data)
                return completion(value)
            }
        }).resume()
    }
    
    // MARK: - fetch() wrapper for empty requests without completion handlers
    final public class func fetch(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) {
        self.fetch(AnyDecodable.self, request: request, url: url, headers: headers) { _ in }
    }
    
    // MARK: - Get a publisher for the request
    final public class func combineFetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) -> AnyPublisher<T, Error> {
        
        let request: URLRequest? = {
            if let request = request {
                return request
            } else if let url = url {
                return URLRequest(url: url)
            } else {
                print("[Networking] You need to provide a request method")
                return nil
            }
        }()
        guard var request = request else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
        var config = URLSessionConfiguration.default
        
        // Set headers
        headers?.set(request: &request, config: &config)
        
        return URLSession(configuration: config).dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Image getter
    final public class func image(url: URL?, to size: CGSize? = nil, completion: @escaping ((_ value: Optional<NSImage>) -> Void)) {
        guard let url = url else { return completion(nil) }
        let request = URLRequest(url: url)
        if let cachedImage = cache.cachedResponse(for: request) {
            return completion(NSImage(data: cachedImage.data) ?? NSImage())
        }

        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard error == nil,
              let data = data,
                let imageData = NSImage(data: data)?.downsample(to: size ?? CGSize(width: 600, height: 600)),
                    let image = NSImage(data: imageData) else {
                      print(error?.localizedDescription ?? "unknown error")
                      return completion(nil)
            }
            cache.storeCachedResponse(CachedURLResponse(response: response!, data: imageData), for: request)
            return completion(image)
        }).resume()
    }
}


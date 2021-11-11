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
}

var standardHeaders = Headers(userAgent: discordUserAgent, contentType: nil, token: AccordCoreVars.shared.token, type: .GET, discordHeaders: true)

final class Request {
    
    // MARK: - Empty Decodable
    struct AnyDecodable: Decodable { }
    
    // MARK: - Perform request with completion handler
    func fetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping ((_ value: Optional<T>) -> Void)) -> Void {
        guard request != nil || url != nil else {
            fatalError("[Networking] Either the URL is invalid or you need to provide a request method")
        }
        
        var request = request ?? URLRequest(url: url!)
        let config = URLSessionConfiguration.default
        
        // Set headers from headers object
        if let headers = headers {
            if let userAgent = headers.userAgent {
                config.httpAdditionalHeaders = ["User-Agent": userAgent]
            }
            if let contentType = headers.contentType, !(headers.json) {
                request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            }
            if let token = headers.token {
                request.addValue(token, forHTTPHeaderField: "Authorization")
            }
            if headers.json {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try! JSONSerialization.data(withJSONObject: headers.bodyObject ?? [:], options: [])
            } else if let bodyObject = headers.bodyObject {
                let bodyString = bodyObject.queryParameters
                request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            }
            if headers.discordHeaders {
                request.addValue("discord.com", forHTTPHeaderField: ":authority")
                request.addValue("https://discord.com", forHTTPHeaderField: "origin")
                request.addValue("empty", forHTTPHeaderField: "sec-fetch-dest")
                request.addValue("cors", forHTTPHeaderField: "sec-fetch-mode")
                request.addValue("same-origin", forHTTPHeaderField: "sec-fetch-site")
                request.addValue(headers.userAgent ?? "WebKit", forHTTPHeaderField: "user-agent")
            }
            if let referer = headers.referer {
                request.addValue(referer, forHTTPHeaderField: "referer")
            }

            request.httpMethod = headers.type.rawValue
        }
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
    func fetch(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) {
        self.fetch(AnyDecodable.self, request: request, url: url, headers: headers) { _ in }
    }
    
    // MARK: - Get a publisher for the request
    func combineFetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) -> AnyPublisher<T, Error> {
        guard request != nil || url != nil else {
            fatalError("[Networking] You need to provide a request method")
        }
        
        var request = request ?? URLRequest(url: url!)
        let config = URLSessionConfiguration.default
        
        // Set headers from headers object
        if let headers = headers {
            if let userAgent = headers.userAgent {
                config.httpAdditionalHeaders = ["User-Agent": userAgent]
            }
            if let contentType = headers.contentType, !(headers.json) {
                request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            }
            if let token = headers.token {
                request.addValue(token, forHTTPHeaderField: "Authorization")
            }
            if headers.json {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try! JSONSerialization.data(withJSONObject: headers.bodyObject ?? [:], options: [])
            } else if let bodyObject = headers.bodyObject {
                let bodyString = bodyObject.queryParameters
                request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            }
            if headers.discordHeaders {
                request.addValue("discord.com", forHTTPHeaderField: ":authority")
                request.addValue("https://discord.com", forHTTPHeaderField: "origin")
                request.addValue("empty", forHTTPHeaderField: "sec-fetch-dest")
                request.addValue("cors", forHTTPHeaderField: "sec-fetch-mode")
                request.addValue("same-origin", forHTTPHeaderField: "sec-fetch-site")
                request.addValue(headers.userAgent ?? "WebKit", forHTTPHeaderField: "user-agent")
            }
            if let referer = headers.referer {
                request.addValue(referer, forHTTPHeaderField: "referer")
            }

            request.httpMethod = headers.type.rawValue
        }
        return URLSession(configuration: config).dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Image getter
    func image(url: URL?, to size: CGSize? = nil, completion: @escaping ((_ value: Optional<NSImage>) -> Void)) {
        guard let url = url else { return }
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


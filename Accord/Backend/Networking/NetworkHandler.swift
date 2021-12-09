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

final class DiscordError: Codable {
    var code: Int
    var message: String?
}

func logOut() {
    _ = KeychainManager.save(key: "me.evelyn.accord.token", data: Data())
    NSApplication.shared.restart()
}

final class Headers {
    init(userAgent: String? = nil, contentType: String? = nil, token: String? = nil, bodyObject: [String:Any]? = nil, type: RequestTypes, discordHeaders: Bool = false, referer: String? = nil, empty: Bool = false, json: Bool = false, cached: Bool = false) {
        self.userAgent = userAgent
        self.contentType = contentType
        self.token = token
        self.bodyObject = bodyObject
        self.type = type
        self.discordHeaders = discordHeaders
        self.referer = referer
        self.empty = empty
        self.json = json
        self.cached = cached
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
    var cached: Bool
    func set(request: inout URLRequest, config: inout URLSessionConfiguration) throws {
        if let userAgent = self.userAgent {
            config.httpAdditionalHeaders = ["User-Agent": userAgent]
        }
        if cached {
            config.requestCachePolicy = .returnCacheDataElseLoad
        }
        if let contentType = self.contentType, !(self.json) {
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if let token = self.token {
            request.addValue(token, forHTTPHeaderField: "Authorization")
        }
        if self.json {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: self.bodyObject ?? [:], options: [])
        } else if let bodyObject = self.bodyObject {
            if self.type == .GET {
                request.url = request.url?.appendingQueryParameters(bodyObject as? [String:String] ?? [:])
            } else {
                let bodyString = bodyObject.queryParameters
                request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            }
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

var standardHeaders = Headers(
    userAgent: discordUserAgent,
    contentType: nil,
    token: AccordCoreVars.shared.token,
    type: .GET,
    discordHeaders: true,
    referer: "https://discord.com/channels/@me"
)

final public class Request {
    
    // MARK: - Empty Decodable
    struct AnyDecodable: Decodable { }
    
    enum FetchErrors: Error {
        case invalidRequest
        case invalidForm
        case badResponse(URLResponse?)
        case notRequired
        case decodingError(String, Error?)
        case noData
    }
    
    // MARK: - Perform request with completion handler
    class func fetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping ((_ value: T?, _ error: Error?) -> Void)) -> Void {
        
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
        guard var request = request else { return completion(nil, FetchErrors.invalidRequest) }
        var config = URLSessionConfiguration.default
        config.setProxy()
        
        // Set headers
        do { try headers?.set(request: &request, config: &config) } catch { return completion(nil, error) }
        
        URLSession(configuration: config).dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data {
                guard error == nil else {
                    print(error?.localizedDescription ?? "Unknown Error")
                    return completion(nil, FetchErrors.badResponse(response))
                }
                if T.self == AnyDecodable.self {
                    return completion(nil, FetchErrors.notRequired) // Bail out if we don't ask for a type
                }
                do {
                    let value = try JSONDecoder().decode(T.self, from: data)
                    return completion(value, nil)
                } catch {
                    guard let error = try? JSONDecoder().decode(DiscordError.self, from: data) else {
                        guard let strError = String(data: data, encoding: .utf8) else { return }
                        return completion(nil, FetchErrors.decodingError(strError, error))
                    }
                    if let message = error.message, message.contains("Unauthorized") {
                        logOut()
                    }
                }
            }
        }).resume()
    }
    
    // MARK: - Perform data request with completion handler
    class func fetch(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping ((_ value: Data?, _ error: Error?) -> Void)) -> Void {
        
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
        guard var request = request else { return completion(nil, FetchErrors.invalidRequest) }
        var config = URLSessionConfiguration.default
        config.setProxy()
        
        // Set headers
        do { try headers?.set(request: &request, config: &config) } catch { return completion(nil, error) }
        
        URLSession(configuration: config).dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data {
                return completion(data, error)
            }
        }).resume()
    }
    
    // MARK: - fetch() wrapper for empty requests without completion handlers
    class func fetch(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) {
        self.fetch(AnyDecodable.self, request: request, url: url, headers: headers) { _, _ in }
    }
    
    // MARK: - Image getter
    class func image(url: URL?, to size: CGSize? = nil, completion: @escaping ((_ value: NSImage?) -> Void)) {
        guard let url = url else { return completion(nil) }
        let request = URLRequest(url: url)
        if let cachedImage = cache.cachedResponse(for: request) {
            return completion(NSImage(data: cachedImage.data) ?? NSImage())
        }
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data,
                  let imageData = NSImage(data: data)?.downsample(to: size),
                  let image = NSImage(data: imageData) else {
                      print(error?.localizedDescription ?? "unknown error")
                      if let data = data {
                          cache.storeCachedResponse(CachedURLResponse(response: response!, data: data), for: request)
                          return completion(NSImage(data: data))
                      } else {
                          print("load failed")
                          return completion(nil)
                      }
            }
            cache.storeCachedResponse(CachedURLResponse(response: response!, data: imageData), for: request)
            return completion(image)
        }).resume()
    }
    
}

final public class RequestPublisher {
    
    // MARK: - Get a publisher for the request
    class func fetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) -> AnyPublisher<T, Error> {
        
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
        do { try headers?.set(request: &request, config: &config) } catch { return Empty(completeImmediately: true).eraseToAnyPublisher() }

        return URLSession(configuration: config).dataTaskPublisher(for: request)
            .retry(3)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Combine Image getter
    class func image(url: URL?, to size: CGSize? = nil) -> AnyPublisher<NSImage?, Error> {
        return Deferred {
            Future { promise in
                guard let url = url else { return promise(.failure(Request.FetchErrors.invalidRequest)) }
                let request = URLRequest(url: url)
                if let cachedImage = cache.cachedResponse(for: request) {
                    print("Using cached image \(url)")
                    promise(.success(NSImage(data: cachedImage.data)))
                    return
                }
                let task = URLSession.shared.dataTask(with: request, completionHandler: { [promise] (data, response, error) in
                    if let data = data {
                        if let size = size, let downsampled = data.downsample(to: size), let image = NSImage(data: downsampled) {
                            print("Successfully downsampled \(url)")
                            cache.storeCachedResponse(CachedURLResponse(response: response!, data: downsampled), for: request)
                            promise(.success(image))
                            return
                        } else if let image = NSImage(data: data) {
                            print("Using original Data \(url)")
                            cache.storeCachedResponse(CachedURLResponse(response: response!, data: data), for: request)
                            promise(.success(image))
                            return
                        }
                    } else if let error = error {
                        print(error, url)
                        return promise(.failure(error))
                    }
                })
                task.resume()
            }
        }.eraseToAnyPublisher()
    }
    
}

fileprivate extension Data {
    // Thanks Amy 🙂
    func downsample(to size: CGSize, scale: CGFloat? = nil) -> Data? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) else { return nil }
        let downsampled = self.downsample(source: imageSource, size: size, scale: scale)
        guard let downsampled = downsampled else { return nil }
        return downsampled
    }
    
    private func downsample(source: CGImageSource, size: CGSize, scale: CGFloat?) -> Data? {
        let maxDimensionInPixels = Swift.max(size.width, size.height) * (scale ?? 0.5)
        let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceShouldCacheImmediately: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        guard let downScaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampledOptions) else { return nil }
        return downScaledImage.png
    }
}

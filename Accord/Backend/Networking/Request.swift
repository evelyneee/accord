//
//  NetworkHandler.swift
//  Accord
//
//  Created by evelyn on 2021-02-27.
//

import Foundation
import Combine
import AppKit
import SwiftUI

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

extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}

func logOut() {
    KeychainManager.save(key: "red.evelyn.accord.token", data: Data())
    NSApp.restart()
}

final class Headers {
    init(userAgent: String = discordUserAgent, contentType: String? = nil, token: String? = nil, bodyObject: [String: Any]? = nil, type: RequestTypes, discordHeaders: Bool = false, referer: String? = nil, empty: Bool = false, json: Bool = false, cached: Bool = false) {
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
    var userAgent: String
    var contentType: String?
    var token: String?
    var bodyObject: [String: Any]?
    var type: RequestTypes
    var discordHeaders: Bool
    var referer: String?
    var empty: Bool?
    var json: Bool
    var cached: Bool
    var superProps: String? {
        let json: [String:Any] = [
            "os":"Mac OS X",
            "browser":"Discord Client",
            "release_channel":"stable",
            "client_version":"0.0.264",
            "os_version":NSWorkspace.kernelVersion,
            "os_arch":NSRunningApplication.current.executableArchitecture == NSBundleExecutableArchitectureX86_64 ? "x64" : "arm64",
            "system_locale":NSLocale.current.languageCode ?? "en-US",
            "client_build_number":dscVersion,
            "client_event_source":NSNull()
        ]
        return try? JSONSerialization.data(withJSONObject: json, options: []).base64EncodedString()
    }
    func set(request: inout URLRequest, config: inout URLSessionConfiguration) throws {
        config.httpAdditionalHeaders = ["User-Agent": userAgent]
        if cached {
            config.requestCachePolicy = .returnCacheDataElseLoad
        }
        if let contentType = self.contentType, !(self.json) {
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if let token = self.token {
            request.addValue(token, forHTTPHeaderField: "authorization")
        }
        if self.json {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: self.bodyObject ?? [:], options: [])
        } else if let bodyObject = self.bodyObject {
            if self.type == .GET {
                request.url = request.url?.appendingQueryParameters(bodyObject as? [String: String] ?? [:])
            } else {
                let bodyString = bodyObject.queryParameters
                request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            }
        }
        if self.discordHeaders {
            request.addValue(self.userAgent, forHTTPHeaderField: "user-agent")
            if let superProps = superProps {
                request.addValue(superProps, forHTTPHeaderField: "x-super-properties")
            } else {
                fatalError("We cannot skip the X-Super-Properties. What are you trying to do, get banned?")
            }
            
            config.httpAdditionalHeaders = [
                "origin":"https://discord.com",
                "authority":"discord.com",
                "method":request.httpMethod ?? "GET",
                "path":request.url?.path ?? "/api/v9/",
                "scheme":"https",
                "x-discord-locale":NSLocale.current.languageCode ?? "en-US",
                "accept":"*/*",
                "accept-encoding":"gzip, deflate, br",
                "accept-language":"en-US,en;q=0.9,en-CA;q=0.8,fr-CA;q=0.7", // hardcoded for now i have no idea what it does
                "sec-fetch-dest":"empty",
                "sec-fetch-mode":"cors",
                "sec-fetch-site":"same-origin",
            ]
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
    token: AccordCoreVars.token,
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
    class func fetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping ((_ value: T?, _ error: Error?) -> Void)) {

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
    class func fetch(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping ((_ value: Data?, _ error: Error?) -> Void)) {

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

        URLSession(configuration: config).dataTask(with: request, completionHandler: { (data, _, error) in
            if let data = data {
                return completion(data, error)
            }
        }).resume()
    }

    // MARK: - fetch() wrapper for empty requests without completion handlers
    class func ping(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) {
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

    static var EmptyImagePublisher: AnyPublisher<NSImage?, Error> = {
        return Empty<NSImage?, Error>.init().eraseToAnyPublisher()
    }()

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
            .retry(2)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .debugAssertNoMainThread()
            .eraseToAnyPublisher()
    }

    // MARK: - Combine Image getter
    class func image(url: URL?, to size: CGSize? = nil) -> AnyPublisher<NSImage?, Error> {
        guard let url = url else { return EmptyImagePublisher }
        let request = URLRequest(url: url)
        if let cachedImage = cache.cachedResponse(for: request) {
            let img = NSImage(data: cachedImage.data)
            return Just.init(img).eraseToAny()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { (data, response) -> NSImage? in
                if let size = size, let downsampled = data.downsample(to: size), let image = NSImage(data: downsampled) {
                    cache.storeCachedResponse(CachedURLResponse(response: response, data: downsampled), for: request)
                    return image
                } else if let image = NSImage(data: data) {
                    cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                    return image
                } else { return nil }
            }
            .debugAssertNoMainThread()
            .eraseToAny()
    }
}

fileprivate extension Data {
    // Thanks Amy :3
    func downsample(to size: CGSize, scale: CGFloat? = nil) -> Data? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) else { return nil }
        let downsampled = self.downsample(source: imageSource, size: size, scale: scale)
        guard let downsampled = downsampled else { return nil }
        return downsampled
    }

    private func downsample(source: CGImageSource, size: CGSize, scale: CGFloat?) -> Data? {
        let maxDimensionInPixels = Swift.max(size.width, size.height) * (scale ?? 1)
        let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceShouldCacheImmediately: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        guard let downScaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampledOptions) else { return nil }
        return downScaledImage.png
    }
}

extension Publisher {
    func eraseToAny() -> AnyPublisher<Self.Output, Error> {
        self.mapError { $0 as Error }.eraseToAnyPublisher()
    }
    func assertNoMainThread() -> Self {
        assert(!Thread.isMainThread)
        return self
    }
    func debugAssertNoMainThread() -> Self {
        #if DEBUG
        assert(!Thread.isMainThread)
        #endif
        return self
    }
}

//
//  FancyTextView.swift
//  Accord
//
//  Created by evelyn on 2021-06-21.
//

import Foundation
import SwiftUI

final class GifServer {
    static var shared = GifServer()
    init(_ a: Bool = false) {
        print("[Accord] innit")
        index = 0
    }
    var timer: Timer? = Timer(timeInterval: Double(0.05), repeats: true) { time in
        GifServer.shared.index += 1 % 20
        print(GifServer.shared.index)
    }
    var index: Int = 0
}

let textQueue = DispatchQueue(label: "Text", attributes: .concurrent)

struct FancyTextView: View {
    @Binding var text: String
    @State var textElement: Text? = nil
    @Binding var channelID: String
    var body: some View {
        HStack {
            if text.contains("`") {
                if #available(macOS 12.0, *) {
                    Text(try! AttributedString(markdown: text))
                } else {
                    Text(text)
                }
            } else {
                HStack(spacing: 0) {
                    if let textView = textElement {
                        textView
                    } else if #available(macOS 12.0, *) {
                        Text(try! AttributedString(markdown: text))
                    } else {
                        Text(text)
                    }
                }
                .onAppear {
                    textQueue.async {
                        let text = TextStuff.shared.getTextArray(splitText: text.components(separatedBy: " "), members: ChannelMembers.shared.channelMembers[channelID] ?? [:]).reduce(Text(""), +)
                        DispatchQueue.main.async {
                            textElement = text
                        }
                    }
                }
                .onChange(of: text) { newValue in
                    textQueue.async {
                        let text = TextStuff.shared.getTextArray(splitText: text.components(separatedBy: " "), members: ChannelMembers.shared.channelMembers[channelID] ?? [:]).reduce(Text(""), +)
                        DispatchQueue.main.async {
                            textElement = text
                        }
                    }
                }
            }
        }
    }
}

final class TextStuff {
    static var shared = TextStuff()
    public func getTextArray(splitText: [String], members: [String:String] = [:]) -> [Text] {
        var textArray: [Text] = []
        print(members, "CHANNEL MEMBERS 2")
        for text in splitText {
            if (text.prefix(2) == "<:" || text.prefix(3) == #"\<:"#) && text.suffix(1) == ">" {
                if let emoteURL = URL(string: "https://cdn.discordapp.com/emojis/\(String(text.dropLast().suffix(18))).png") {
                    print(emoteURL, "EMOTE URL")
                    let config = URLSessionConfiguration.default
                    config.urlCache = cache
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
                    let session = URLSession(configuration: config)
                    let request = URLRequest(url: emoteURL, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                    if let data = cache.cachedResponse(for: request)?.data {
                        if splitText.count == 1 {
                            textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                        } else {
                            textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 15, height: 15)) ?? NSImage())))"))
                        }
                    } else {
                        session.dataTask(with: request, completionHandler: { (data, response, error) in
                            if let data = data, let response = response {
                            let cachedData = CachedURLResponse(response: response, data: data)
                                cache.storeCachedResponse(cachedData, for: request)
                                if splitText.count <= 3 {
                                    textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                                } else {
                                    textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 15, height: 15)) ?? NSImage())))"))
                                }
                            }
                        }).resume()
                    }
                }
            } else if (text.prefix(4) == #"\<a:"# || text.prefix(3) == "<a:") && text.suffix(1) == ">" {
                guard let emoteURL = URL(string: "https://cdn.discordapp.com/emojis/\(String(text.dropLast().suffix(18))).gif") else { break }
                if splitText.count == 1 {
                    let config = URLSessionConfiguration.default
                    config.urlCache = cache
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
                    let session = URLSession(configuration: config)
                    let cache = URLCache.shared
                    let request = URLRequest(url: emoteURL, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                    if let data = cache.cachedResponse(for: request)?.data {
                        if let amyGif = Gif(data: data) {
                            DispatchQueue.main.async {
                                let animatedImages: [NSImage] = amyGif.animatedImages!
                                print(animatedImages)
                                let duration = Double(CFTimeInterval(amyGif.calculatedDuration ?? 0))
                                _ = GifServer()
                                textArray.append(Text("\(Image(nsImage: animatedImages[GifServer.shared.index % (animatedImages.count)] ).resizable())"))
                                print(Double(duration / Double(animatedImages.count )))
                            }
                        }
                    } else {
                        session.dataTask(with: request, completionHandler: { (data, response, error) in
                            if let data = data, let response = response {
                            let cachedData = CachedURLResponse(response: response, data: data)
                                cache.storeCachedResponse(cachedData, for: request)
                                if let amyGif = Gif(data: data) {
                                    DispatchQueue.main.async {
                                        let animatedImages: [NSImage] = amyGif.animatedImages!
                                        print(animatedImages)
                                        let duration = Double(CFTimeInterval(amyGif.calculatedDuration ?? 0))
                                        let gifServer = GifServer.init()
                                        textArray.append(Text("\(Image(nsImage: animatedImages[gifServer.index % (animatedImages.count)] ).resizable())"))
                                        print(Double(duration / Double(animatedImages.count )))
                                    }
                                }
                            }
                        }).resume()
                    }
                    
                } else {
                    let config = URLSessionConfiguration.default
                    config.urlCache = cache
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
                    let session = URLSession(configuration: config)
                    let request = URLRequest(url: emoteURL, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                    if let data = cache.cachedResponse(for: request)?.data {
                        textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 15, height: 15)) ?? NSImage())))"))
                    } else {
                        session.dataTask(with: request, completionHandler: { (data, response, error) in
                            if let data = data, let response = response {
                            let cachedData = CachedURLResponse(response: response, data: data)
                                cache.storeCachedResponse(cachedData, for: request)
                                textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 15, height: 15)) ?? NSImage())))"))
                            }
                        }).resume()
                    }
                }

            } else if text.prefix(5) == "https" && text.suffix(4) == ".png" {
                if let url = URL(string: text) {
                    let config = URLSessionConfiguration.default
                    config.urlCache = cache
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
                    let session = URLSession(configuration: config)
                    let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                    if let data = cache.cachedResponse(for: request)?.data {
                        textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                    } else {
                        session.dataTask(with: request, completionHandler: { (data, response, error) in
                            if let data = data, let response = response {
                            let cachedData = CachedURLResponse(response: response, data: data)
                                cache.storeCachedResponse(cachedData, for: request)
                                textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                            }
                        }).resume()
                    }
                }
            } else if text.prefix(5) == "https" && text.suffix(4) == ".gif" {
                if let url = URL(string: text) {
                    let config = URLSessionConfiguration.default
                    config.urlCache = cache
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
                    let session = URLSession(configuration: config)
                    let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                    if let data = cache.cachedResponse(for: request)?.data {
                        textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                    } else {
                        session.dataTask(with: request, completionHandler: { (data, response, error) in
                            if let data = data, let response = response {
                            let cachedData = CachedURLResponse(response: response, data: data)
                                cache.storeCachedResponse(cachedData, for: request)
                                textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                            }
                        }).resume()
                    }
                }
            } else if (text.prefix(3) == "<@!" || text.prefix(4) == #"\<@!"# || text.prefix(2) == "<@") && text.suffix(1) == ">" && members != [:] {
                textArray.append(Text("@\(members[String(text.dropLast().suffix(18))] ?? "Unknown User")").underline().foregroundColor(Color.blue))
                textArray.append(Text(" "))
            } else {
                if #available(macOS 12.0, *) {
                    textArray.append(Text(try! AttributedString(markdown: "\(text)")))
                    textArray.append(Text(" "))
                } else {
                    textArray.append(Text("\(text) "))
                }
            }
        }
        return textArray
    }


    public func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("[Accord] invalid regex \(error.localizedDescription)")
            return []
        }
    }
}



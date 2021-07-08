//
//  FancyTextView.swift
//  Accord
//
//  Created by evelyn on 2021-06-21.
//

import Foundation
import SwiftUI

struct FancyTextView: View {
    @Binding var text: String
    @State var textElement: Text? = nil
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
                    } else {
                        if #available(macOS 12.0, *) {
                            Text(try! AttributedString(markdown: text))
                        } else {
                            Text(text)
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.async {
                        textElement = getTextArray(splitText: text.components(separatedBy: " ")).reduce(Text(""), +)
                    }
                }
                .onChange(of: text) { newValue in
                    textElement = getTextArray(splitText: text.components(separatedBy: " ")).reduce(Text(""), +)
                }
            }
        }
    }
}


public func getTextArray(splitText: [String]) -> [Text] {
    var textArray: [Text] = []
    for text in splitText {
        if (text.prefix(2) == "<:" || text.prefix(2) == #"\<:"# || text.prefix(2) == "<a:") && text.suffix(1) == ">" {
            for id in text.capturedGroups(withRegex: #"<:\w+:(\d+)>"#) {
                if let _ = URL(string: "https://cdn.discordapp.com/emojis/\(id).png") {
                    if splitText.count == 1 {
                        if let url = URL(string: "https://cdn.discordapp.com/emojis/\(id).png") {
                            let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                            if let data = cache?.cachedResponse(for: request)?.data {
                                textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                            } else {
                                URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                    if let data = data, let response = response {
                                    let cachedData = CachedURLResponse(response: response, data: data)
                                        cache?.storeCachedResponse(cachedData, for: request)
                                        textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                                    }
                                }).resume()
                            }
                        }
                    } else {
                        if let url = URL(string: "https://cdn.discordapp.com/emojis/\(id).png") {
                            let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                            if let data = cache?.cachedResponse(for: request)?.data {
                                textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 15, height: 15)) ?? NSImage())))"))
                            } else {
                                URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                    if let data = data, let response = response {
                                    let cachedData = CachedURLResponse(response: response, data: data)
                                        cache?.storeCachedResponse(cachedData, for: request)
                                        textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 15, height: 15)) ?? NSImage())))"))
                                    }
                                }).resume()
                            }
                        }
                    }
                }
            }
        } else if text.prefix(5) == "https" && text.suffix(4) == ".png" {
            if let url = URL(string: text) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                if let data = cache?.cachedResponse(for: request)?.data {
                    textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache?.storeCachedResponse(cachedData, for: request)
                            textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                        }
                    }).resume()
                }
            }
        } else if text.prefix(5) == "https" && text.suffix(4) == ".gif" {
            if let url = URL(string: text) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                if let data = cache?.cachedResponse(for: request)?.data {
                    textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                } else {
                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache?.storeCachedResponse(cachedData, for: request)
                            textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                        }
                    }).resume()
                }
            }
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
        print("invalid regex \(error.localizedDescription)")
        return []
    }
}


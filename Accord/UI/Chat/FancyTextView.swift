//
//  FancyTextView.swift
//  Accord
//
//  Created by evelyn on 2021-06-21.
//

import Foundation
import SwiftUI

let textQueue = DispatchQueue(label: "Text", attributes: .concurrent)

struct FancyTextView: View {
    @Binding var text: String
    @State var textElement: Text? = nil
    @Binding var channelID: String
    var body: some View {
        HStack(spacing: 0) {
            if let textView = textElement {
                textView
            } else {
                Text(text)
            }
        }
        .onAppear {
            textQueue.async {
                text.markdown(members: ChannelMembers.shared.channelMembers[channelID] ?? [:]) { markdown in
                    guard let markdown = markdown else { return }
                    self.textElement = markdown
                }
            }
        }
        .onChange(of: text) { newValue in
            textQueue.async {
                text.markdown(members: ChannelMembers.shared.channelMembers[channelID] ?? [:]) { markdown in
                    guard let markdown = markdown else { return }
                    self.textElement = markdown
                }
            }
        }
    }
}

extension String {
    public func marked() -> String {
        let textArray = self.components(separatedBy: " ")
        let config = URLSessionConfiguration.default
        var returnString: String = ""
        config.urlCache = cache
        config.setProxy()
        for text in textArray {
            if text.prefix(31) == "https://open.spotify.com/track/" {
                let sem = DispatchSemaphore(value: 0)
                SongLink.shared.getSong(song: text) { song in
                    if let song = song {
                        returnString.append(song.linksByPlatform.appleMusic.url)
                        sem.signal()
                    }
                }
                sem.wait()
            } else {
                returnString.append(text)
            }
        }
        return returnString
    }
}

final class AccordMarkdown {
    static var shared = AccordMarkdown()
    typealias completionBlock = ((_ value: Optional<Text>) -> Void)
    final func concatenateAndPrepare(text: String, members: [String:String] = [:], completion: @escaping completionBlock) {
        let split = text.components(separatedBy: " ")
        var splitCount = split.count
        var textArray = [Text]()  {
            didSet {
                if textArray.count == splitCount {
                    return completion(textArray.reduce(Text(""), +))
                }
            }
        }
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.setProxy()
        let session = URLSession(configuration: config)
        for text in split {
            // I'm sorry.
            if ((text.prefix(2) == "<:" || text.prefix(3) == #"\<:"#) && text.suffix(1) == ">") || ((text.prefix(4) == #"\<a:"# || text.prefix(3) == "<a:") && text.suffix(1) == ">") {
                if let emoteURL = URL(string: "https://cdn.discordapp.com/emojis/\(String(text.dropLast().suffix(18))).png?size=40") {
                    Request.image(url: emoteURL, to: CGSize(width: 40, height: 40)) { image in
                        if let image = image {
                            textArray.append(Text("\(Image(nsImage: image))"))
                        }
                    }
                }
            } else if text.prefix(5) == "https" && text.suffix(4) == ".gif" {
                if let url = URL(string: text) {
                    let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                    if let data = cache.cachedResponse(for: request)?.data {
                        textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.downsample(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                    } else {
                        session.dataTask(with: request, completionHandler: { (data, response, error) in
                            if let data = data, let response = response {
                            let cachedData = CachedURLResponse(response: response, data: data)
                                cache.storeCachedResponse(cachedData, for: request)
                                textArray.append(Text("\(Image(nsImage: (NSImage(data: data)?.downsample(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                            }
                        }).resume()
                    }
                }
            } else if text.prefix(5) == "https" && text.suffix(4) == ".png" {
                if let url = URL(string: text) {
                    Request.image(url: url, to: CGSize(width: 40, height: 40)) { image in
                        if let image = image {
                            textArray.append(Text("\(Image(nsImage: image))"))
                        }
                    }
                }
            } else if text.prefix(31) == "https://open.spotify.com/track/" {
                SongLink.shared.getSong(song: text) { song in
                    if let song = song {
                        textArray.append(Text(song.linksByPlatform.appleMusic.url))
                    } else {
                        textArray.append(Text(text))
                    }
                }
            } else if text.hasPrefix("<@!") && text.hasSuffix(">") {
                let id = String(text.dropLast().dropFirst(3))
                if #available(macOS 12.0, *) {
                    textArray.append(Text("@\(members[id] ?? "Unknown user") ").foregroundColor(Color(nsColor: .linkColor)).underline())
                } else {
                    textArray.append(Text("@\(members[id] ?? "Unknown user") ").foregroundColor(Color.blue).underline())
                }
            } else {
                if #available(macOS 12.0, *) {
                    textArray.append(Text(try! AttributedString(markdown: text)))
                    textArray.append(Text(" "))
                    splitCount++
                } else {
                    textArray.append(Text("\(text) "))
                }
            }
        }
    }
}

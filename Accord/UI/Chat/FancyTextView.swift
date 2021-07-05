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
                        textArray.append(Text("\(Image(nsImage: (NSImage(data: ImageHandling.shared?.sendRequest(url: "https://cdn.discordapp.com/emojis/\(id).png") ?? Data())?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
                    } else {
                        textArray.append(Text("\(Image(nsImage: (NSImage(data: ImageHandling.shared?.sendRequest(url: "https://cdn.discordapp.com/emojis/\(id).png") ?? Data())?.resizeMaintainingAspectRatio(withSize: NSSize(width: 15, height: 15)) ?? NSImage())))"))
                    }
                }
            }
        } else if text.prefix(5) == "https" && text.suffix(4) == ".png" {
            textArray.append(Text("\(Image(nsImage: (NSImage(data: ImageHandling.shared?.sendRequest(url: text) ?? Data())?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
        } else if text.prefix(5) == "https" && text.suffix(4) == ".gif" {
            textArray.append(Text("\(Image(nsImage: (NSImage(data: ImageHandling.shared?.sendRequest(url: text) ?? Data())?.resizeMaintainingAspectRatio(withSize: NSSize(width: 40, height: 40)) ?? NSImage())))"))
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


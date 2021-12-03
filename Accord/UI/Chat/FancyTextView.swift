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

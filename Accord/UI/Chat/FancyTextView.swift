//
//  FancyTextView.swift
//  Accord
//
//  Created by evelyn on 2021-06-21.
//

import Foundation
import SwiftUI
import Combine

let textQueue = DispatchQueue(label: "Text load queue")

struct FancyTextView: View {

    @Binding var text: String
    var channelID: String
    @State var textElement: Text? = nil
    @State var cancellable: AnyCancellable? = nil
    func load(text: String) {
        textQueue.async {
            self.cancellable = Markdown.markAll(text: text, ChannelMembers.shared.channelMembers[channelID] ?? [:])
                .assertNoFailure()
                .sink(receiveValue: { text in
                    DispatchQueue.main.async {
                        self.textElement = text
                    }
                })
        }
    }
    
    var body: some View {
        Group {
            textElement ?? Text(text)
        }
        .onAppear(perform: {
            self.load(text: self.text)
        })
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

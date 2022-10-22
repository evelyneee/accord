//
//  StickersView.swift
//  Accord
//
//  Created by evelyn on 2022-10-13.
//

import SwiftUI

struct StickersView: View {
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    var stickers: [Sticker] {
        get async {
            await withCheckedContinuation { continuation in
                let folders = appModel.folders
                DispatchQueue.global().async {
                    continuation.resume(with: .success(Array(folders
                        .lazy
                        .map(\.guilds)
                        .joined()
                        .compactMap(\.stickers)
                        .joined())))
                }
            }
        }
    }
    
    @Environment(\.guildID)
    var guildID: String
    
    @Environment(\.channelID)
    var channelID: String
    
    @State var stickersLoaded: [Sticker] = []
    
    var body: some View {
        ScrollView {
            GridStack(self.$stickersLoaded, rowAlignment: .center, columns: 2) { $sticker in
                Button {
                    // {"content":"","nonce":"1033465155922427904","tts":false,"sticker_ids":["862588476410691624"]}
                    Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages"), headers: Headers(
                        token: Globals.token,
                        bodyObject: ["content": "", "tts": false, "nonce": generateFakeNonce(), "sticker_ids":[sticker.id]],
                        type: .POST,
                        discordHeaders: true,
                        referer: "https://discord.com/channels/\(guildID)/\(channelID)",
                        empty: true,
                        json: true
                    ))
                } label: {
                    if sticker.format_type == .lottie {
                        GifView("https://cdn.discordapp.com/stickers/\(sticker.id).json")
                            .frame(width: 75, height: 75)
                            .cornerRadius(3)
                            .drawingGroup()
                    } else if sticker.format_type == .apng {
                        GifView("https://cdn.discordapp.com/stickers/\(sticker.id).png?size=96")
                            .frame(width: 75, height: 75)
                            .cornerRadius(3)
                            .drawingGroup()
                    } else {
                        Attachment("https://media.discordapp.net/stickers/\(sticker.id).png?size=96")
                            .equatable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .cornerRadius(3)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .listRowBackground(Color.clear)
        .task {
            self.stickersLoaded = await self.stickers
        }
    }
}

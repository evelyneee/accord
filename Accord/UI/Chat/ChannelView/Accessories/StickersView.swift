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
    
    @State var stickersLoaded: [Sticker] = []
    
    var body: some View {
        List {
            GridStack(self.$stickersLoaded, rowAlignment: .center, columns: 2) { $sticker in
                if sticker.format_type == .lottie {
                    GifView("https://cdn.discordapp.com/stickers/\(sticker.id).json")
                        .frame(width: 75, height: 75)
                        .cornerRadius(3)
                } else {
                    Attachment("https://media.discordapp.net/stickers/\(sticker.id).png?size=160")
                        .equatable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .cornerRadius(3)
                }
            }
        }
        .task {
            self.stickersLoaded = await self.stickers
        }
    }
}

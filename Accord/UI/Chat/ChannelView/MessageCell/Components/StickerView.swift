//
//  StickerView.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct StickerView: View {
    
    var stickerItems: [StickerItem]
    private let leftPadding: CGFloat = 44.5
    
    var body: some View {
        ForEach(stickerItems, id: \.id) { sticker in
            if sticker.format_type == .lottie {
                GifView("https://cdn.discordapp.com/stickers/\(sticker.id).json")
                    .frame(width: 160, height: 160)
                    .cornerRadius(3)
                    .padding(.leading, leftPadding)
            } else {
                Attachment("https://media.discordapp.net/stickers/\(sticker.id).png?size=160")
                    .equatable()
                    .frame(width: 160, height: 160)
                    .cornerRadius(3)
                    .padding(.leading, leftPadding)
            }
        }
    }
}

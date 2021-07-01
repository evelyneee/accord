//
//  AttachmentView.swift
//  Accord
//
//  Created by evelyn on 2021-07-01.
//

import SwiftUI
import AVKit

struct AttachmentView: View {
    @Binding var media: [AttachedFiles?]
    var body: some View {
        VStack {
            ForEach(0..<media.count, id: \.self) { index in
                if String((media[index]?.content_type ?? "").prefix(6)) == "image/" {
                    Attachment((media[index]?.url)!)
                        .cornerRadius(5)
                } else if String((media[index]?.content_type ?? "").prefix(6)) == "video/" {
                    VideoPlayer(player: AVPlayer(url: URL(string: (media[index]?.url)!)!))
                        .frame(width: 400, height: 300)
                        .padding(.horizontal, 45)
                        .cornerRadius(5)
                }
            }
        }
    }
}

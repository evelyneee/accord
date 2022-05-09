//
//  EmbedView.swift
//  Accord
//
//  Created by evelyn on 2021-10-24.
//

import AVKit
import SwiftUI

struct EmbedView: View, Equatable {
    weak var embed: Embed?

    static func == (_: EmbedView, _: EmbedView) -> Bool {
        true
    }

    var columns: [GridItem] = GridItem.multiple(count: 4)

    var body: some View {
        HStack(spacing: 0) {
            if let color = embed?.color {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(int: color))
                    .frame(width: 4)
                    .padding(.trailing, 5)
            } else {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black)
                    .frame(width: 4)
                    .padding(.trailing, 5)
            }
            VStack(alignment: .leading) {
                if let author = embed?.author {
                    HStack {
                        if let iconURL = author.proxy_icon_url ?? author.icon_url {
                            Attachment(iconURL, size: CGSize(width: 24, height: 24))
                                .equatable()
                                .frame(width: 15, height: 15)
                                .clipShape(Circle())
                        }
                        if let urlString = author.url, let url = URL(string: urlString) {
                            Link(author.name, destination: url)
                        } else {
                            Text(author.name)
                                .fontWeight(.semibold)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                if let title = embed?.title {
                    Text(title)
                        .fontWeight(.semibold)
                }
                if let description = embed?.description {
                    AsyncMarkdown(description)
                }
                if let image = embed?.image {
                    Attachment(image.url, size: CGSize(width: image.width ?? 400, height: image.width ?? 300))
                        .equatable()
                        .cornerRadius(5)
                        .maxFrame(width: 380, height: 300, originalWidth: image.width ?? 0, originalHeight: image.height ?? 0)
                }
                if let video = embed?.video,
                   let urlString = video.proxy_url ?? video.url,
                   let url = URL(string: urlString)
                {
                    VideoPlayer(player: AVPlayer(url: url))
                        .cornerRadius(5)
                        .maxFrame(width: 380, height: 300, originalWidth: video.width ?? 0, originalHeight: video.height ?? 0)
                }
                if let fields = embed?.fields {
                    LazyVGrid(columns: columns, alignment: .leading) {
                        ForEach(fields, id: \.name) { field in
                            VStack(alignment: .leading) {
                                Text(field.name)
                                    .lineLimit(0)
                                    .font(.subheadline)
                                AsyncMarkdown(field.value)
                                    .equatable()
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 5)
            Spacer()
        }
        .frame(maxWidth: 400)
        .background(Color(NSColor.disabledControlTextColor).opacity(0.2))
        .cornerRadius(5)
    }
}

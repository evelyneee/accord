//
//  EmbedView.swift
//  Accord
//
//  Created by evelyn on 2021-10-24.
//

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
                Color(NSColor.color(from: color) ?? NSColor.gray).frame(width: 3).padding(.trailing, 5)
            }
            VStack(alignment: .leading) {
                if let author = embed?.author {
                    HStack {
                        if let iconURL = author.proxy_icon_url {
                            Attachment(iconURL, size: CGSize(width: 24, height: 24))
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        } else if let iconURL = author.icon_url {
                            Attachment(iconURL, size: CGSize(width: 24, height: 24))
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        }
                        if let urlString = author.url, let url = URL(string: urlString) {
                            Link(author.name, destination: url)
                        } else {
                            Text(author.name)
                        }
                    }
                }
                if let title = embed?.title {
                    Text(title)
                        .fontWeight(.bold)
                        .font(.title3)
                }
                if let description = embed?.description {
                    if #available(macOS 12.0, *) {
                        Text((try? AttributedString(markdown: description)) ?? AttributedString(description))
                    } else {
                        Text(description)
                    }
                }
                if let image = embed?.image {
                    Attachment(image.url, size: CGSize(width: image.width ?? 400, height: image.width ?? 300))
                        .cornerRadius(5)
                        .frame(width: 250)
                }
                if let fields = embed?.fields {
                    LazyVGrid(columns: columns, alignment: .leading) {
                        ForEach(fields, id: \.name) { field in
                            VStack(alignment: .leading) {
                                Text(field.name)
                                    .lineLimit(0)
                                    .font(.subheadline)
                                AsyncMarkdown(field.value)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 5)
    }
}

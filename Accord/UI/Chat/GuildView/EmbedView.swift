//
//  EmbedView.swift
//  Accord
//
//  Created by evelyn on 2021-10-24.
//

import SwiftUI

struct EmbedView: View {
    var embed: Embed
    init(_ embed: Embed) {
        self.embed = embed
    }
    var body: some View {
        HStack(spacing: 0) {
            if let color = embed.color {
                Color(NSColor.color(from: color) ?? NSColor.gray).frame(width: 2)
            }
            VStack(alignment: .leading) {
                if let title = embed.title {
                    Text(title)
                        .fontWeight(.bold)
                        .font(.title3)
                }
                if let description = embed.description {
                    Text(description)
                }
                if let image = embed.image {
                    Attachment(image.url)
                }
            }
            .frame(width: 248)
        }
        .frame(width: 250)
    }
}

//
//  EmbedView.swift
//  Accord
//
//  Created by evelyn on 2021-10-24.
//

import SwiftUI

struct EmbedView: View, Equatable {
    weak var embed: Embed?
    
    static func == (lhs: EmbedView, rhs: EmbedView) -> Bool {
        return true
    }

    var body: some View {
        HStack(spacing: 0) {
            if let color = embed?.color {
                Color(NSColor.color(from: color) ?? NSColor.gray).frame(width: 2)
            }
            VStack(alignment: .leading) {
                if let title = embed?.title {
                    Text(title)
                        .fontWeight(.bold)
                        .font(.title3)
                }
                if let description = embed?.description {
                    Text(description)
                }
                if let image = embed?.image {
                    Attachment(image.url, size: CGSize(width: image.width ?? 400, height: image.width ?? 300))
                }
            }
        }
        .frame(width: 250)
    }
}

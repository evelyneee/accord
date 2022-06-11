//
//  ReactionsGrid.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct ReactionsGridView: View {
    var reactions: [Reaction]

    var body: some View {
        GridStack(reactions, rowAlignment: .leading, columns: 6, content: { reaction in
            HStack(spacing: 4) {
                if let id = reaction.emoji.id {
                    Attachment(cdnURL + "/emojis/\(id).png?size=16")
                        .equatable()
                        .frame(width: 16, height: 16)
                } else if let name = reaction.emoji.name {
                    Text(name)
                        .frame(width: 16, height: 16)
                }
                Text(String(reaction.count))
                    .fontWeight(.medium)
            }
            .padding(4)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(4)
        })
        .fixedSize()
    }
}

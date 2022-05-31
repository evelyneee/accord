//
//  InteractionView.swift
//  Accord
//
//  Created by evelyn on 2022-05-30.
//

import SwiftUI

struct InteractionView: View {
    var interaction: Interaction
    var isSameAuthor: Bool
    @Binding var replyRole: String?
    var body: some View {
        HStack {
            Attachment(pfpURL(interaction.user?.id, interaction.user?.avatar, "16"))
                .equatable()
                .frame(width: 15, height: 15)
                .clipShape(Circle())
            Text(interaction.user?.username ?? "")
                .font(.subheadline)
                .foregroundColor({ () -> Color in
                    if let replyRole = replyRole, let color = roleColors[replyRole]?.0, !isSameAuthor {
                        return Color(int: color)
                    }
                    return Color.primary
                }())
                .fontWeight(.semibold)
            Text("/" + interaction.name)
                .font(.subheadline)
                .lineLimit(0)
                .foregroundColor(.secondary)
        }
    }
}

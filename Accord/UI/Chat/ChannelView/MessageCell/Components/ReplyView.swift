//
//  ReplyView.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct ReplyView: View {
    
    let reply: Reply
    var replyNick: String?
    @Binding var replyRole: String?
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 5)
                .trim(from: 0.5, to: 0.75)
                .stroke(.gray.opacity(0.4), lineWidth: 2)
                .frame(width: 53, height: 17)
                .padding(.bottom, -15)
                .padding(.trailing, -30)
            Attachment(pfpURL(reply.author?.id, reply.author?.avatar, discriminator: reply.author?.discriminator ?? "0005", "16"))
                .equatable()
                .frame(width: 15, height: 15)
                .clipShape(Circle())
            Text(replyNick ?? reply.author?.username ?? "")
                .font(.subheadline)
                .foregroundColor({ () -> Color in
                    if let replyRole = replyRole, let color = roleColors[replyRole]?.0 {
                        return Color(int: color)
                    }
                    return Color.primary
                }())
                .fontWeight(.medium)
            Text(reply.content)
                .font(.subheadline)
                .lineLimit(0)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, -3)
        .padding(.leading, 15)
    }
}

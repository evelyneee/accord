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
                .fixedSize()
            Attachment(pfpURL(reply.author?.id, reply.author?.avatar, discriminator: reply.author?.discriminator ?? "0005", "16"))
                .equatable()
                .frame(width: 15, height: 15)
                .clipShape(Circle())
                .fixedSize()
            Text(replyNick ?? reply.author?.username ?? "")
                .font(.subheadline)
                .foregroundColor({ () -> Color in
                    if let replyRole = replyRole, let color = Storage.roleColors[replyRole]?.0 {
                        return Color(int: color)
                    }
                    return Color.primary
                }())
                .fontWeight(.medium)
            Button(action: { [unowned reply] in
                ChannelView.scrollTo.send((reply.channel_id, reply.id))
            }, label: { [weak reply] in
                let content = reply?.content ?? ""
                let hasAttachment = !(reply?.attachments ?? []).isEmpty
                Text(content != "" ? content : hasAttachment ? "Click to see attachment" : "       ")
                    .font(.subheadline)
                    .lineLimit(0)
                    .foregroundColor(.secondary)
            })
            .buttonStyle(.borderless)
        }
        .padding(.bottom, -3)
        .padding(.leading, 15)
    }
}

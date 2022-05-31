//
//  AuthorText.swift
//  Accord
//
//  Created by evelyn on 2022-05-30.
//

import SwiftUI

struct AuthorTextView: View {
    
    var message: Message
    var pronouns: String?
    var nick: String?
    @Binding var role: String?
    var body: some View {
        HStack(spacing: 1) {
            Text(nick ?? message.author?.username ?? "Unknown User")
                .foregroundColor({ () -> Color in
                    if let role = role, let color = roleColors[role]?.0, !message.isSameAuthor {
                        return Color(int: color)
                    }
                    return Color.primary
                }())
                .font(.chatTextFont)
                .fontWeight(.semibold)
                +
            Text("  \(message.processedTimestamp ?? "")")
                .foregroundColor(Color.secondary)
                .font(.subheadline)
                +
            Text(message.edited_timestamp != nil ? " (edited at \(message.edited_timestamp?.makeProperHour() ?? "unknown time"))" : "")
                .foregroundColor(Color.secondary)
                .font(.subheadline)
                +
            Text((pronouns != nil) ? " • \(pronouns ?? "Use my name")" : "")
                .foregroundColor(Color.secondary)
                .font(.subheadline)
            if message.author?.bot == true {
                Text("Bot")
                    .padding(.horizontal, 4)
                    .foregroundColor(Color.white)
                    .font(.subheadline)
                    .background(Capsule().fill().foregroundColor(Color.red))
                    .padding(.horizontal, 4)
            }
            if message.author?.system == true {
                Text("System")
                    .padding(.horizontal, 4)
                    .foregroundColor(Color.white)
                    .font(.subheadline)
                    .background(Capsule().fill().foregroundColor(Color.purple))
                    .padding(.horizontal, 4)
           }
        }

    }
}

//
//  MessageCellView.swift
//  Accord
//
//  Created by evelyn on 2021-12-12.
//

import Foundation
import SwiftUI
import AppKit

let colorQueue = DispatchQueue(label: "ColorQueue")

struct MessageCellView: View {
    @Binding var message: Message
    var nick: String?
    var replyNick: String?
    var pronouns: String?
    @Binding var role: String?
    @Binding var replyRole: String?
    @Binding var replyingTo: Message?
    @State var popup: Bool = false
    @State var color: NSColor = NSColor.textColor
    @State var replyColor: NSColor = NSColor.textColor
    var body: some View {
        VStack(alignment: .leading) {
            if let reply = message.referenced_message {
                HStack {
                    Attachment(pfpURL(reply.author?.id, reply.author?.avatar)).equatable()
                        .frame(width: 15, height: 15)
                        .scaledToFit()
                        .clipShape(Circle())
                    Text(replyNick ?? reply.author?.username ?? "")
                        .foregroundColor(Color(replyColor))
                        .fontWeight(.semibold)
                    Text(reply.content)
                        .lineLimit(0)
                }
                .padding(.leading, 43)
            }
            HStack(alignment: .top) {
                if !(message.isSameAuthor()) {
                    Button(action: {
                        popup.toggle()
                    }) { [weak message] in
                        Attachment(pfpURL(message?.author?.id, message?.author?.avatar)).equatable()
                            .frame(width: 33, height: 33)
                            .scaledToFit()
                            .clipShape(Circle())
                    }
                    .popover(isPresented: $popup, content: { [weak message] in
                        if let message = message {
                            PopoverProfileView(user: Binding.constant(message.author))
                        }
                    })
                    .buttonStyle(BorderlessButtonStyle())
                }
                VStack(alignment: .leading) {
                    if message.isSameAuthor() {
                        FancyTextView(text: $message.content, channelID: message.channel_id)
                            .padding(.leading, 41)
                    } else {
                        Text(nick ?? message.author?.username ?? "Unknown User")
                            .foregroundColor(Color(color))
                            .fontWeight(.semibold)
                        +
                        Text(" — \(message.timestamp.makeProperDate())")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                        +
                        Text((pronouns != nil) ? " — \(pronouns ?? "Use my name")" : "")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                        FancyTextView(text: $message.content, channelID: message.channel_id)
                    }
                }
                Spacer()
                // MARK: - Quick Actions
                QuickActionsView(message: message, replyingTo: $replyingTo)
            }
            if let embeds = message.embeds, !embeds.isEmpty {
                ForEach(message.embeds ?? [], id: \.id) { embed in
                    EmbedView(embed: embed).equatable()
                        .padding(.leading, 41)
                }
            }
            
            AttachmentView(message.attachments).equatable()
                .padding(.leading, 41)
        }
        .id(message.id)
        .onAppear {
            colorQueue.async {
                if let role = role, let color = roleColors[role]?.0, let nsColor = NSColor.color(from: color) {
                    self.color = nsColor
                }
                if let role = replyRole, let color = roleColors[role]?.0, let nsColor = NSColor.color(from: color) {
                    self.replyColor = nsColor
                }
            }
        }
        .onChange(of: self.role, perform: { _ in
            colorQueue.async {
                if let role = role, let color = roleColors[role]?.0, let nsColor = NSColor.color(from: color) {
                    self.color = nsColor
                }
                if let role = replyRole, let color = roleColors[role]?.0, let nsColor = NSColor.color(from: color) {
                    self.replyColor = nsColor
                }
            }
        })
    }
}

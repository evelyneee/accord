//
//  MessageCellView.swift
//  Accord
//
//  Created by evelyn on 2021-12-12.
//

import Foundation
import SwiftUI
import AppKit
import Combine

struct MessageCellView: View {
    var message: Message
    var nick: String?
    var replyNick: String?
    var pronouns: String?
    @Binding var role: String?
    @Binding var replyRole: String?
    @Binding var replyingTo: Message?
    @State var popup: Bool = false
    @State var color: Color = Color(NSColor.textColor)
    @State var replyColor: Color = Color(NSColor.textColor)
    @State var textElement: Text?
    @State var bag = Set<AnyCancellable>()
    @State var hovered: Bool = false
    var body: some View {
        VStack(alignment: .leading) {
            if let reply = message.referenced_message {
                HStack { [weak reply] in
                    Attachment(pfpURL(reply?.author?.id, reply?.author?.avatar, "16")).equatable()
                        .frame(width: 15, height: 15)
                        .clipShape(Circle())
                    Text(replyNick ?? reply?.author?.username ?? "")
                        .foregroundColor(replyColor)
                        .fontWeight(.semibold)
                    if #available(macOS 12.0, *) {
                        Text(try! AttributedString(markdown: reply?.content ?? ""))
                            .lineLimit(0)
                    } else {
                        Text(reply?.content ?? "")
                            .lineLimit(0)
                    }
                }
                .padding(.leading, 47)
            }
            HStack { [unowned message] in
                if !message.isSameAuthor {
                    Button(action: {
                        popup.toggle()
                    }) {
                        NavigationLazyView(Attachment(pfpURL(message.author?.id, message.author?.avatar, "24")).equatable())
                            .frame(width: 33, height: 33)
                            .clipShape(Circle())
                    }
                    .popover(isPresented: $popup, content: {
                        PopoverProfileView(user: Binding.constant(message.author))
                    })
                    .buttonStyle(BorderlessButtonStyle())
                }
                VStack(alignment: .leading) {
                    if message.isSameAuthor {
                        textElement?.padding(.leading, 41) ?? Text(message.content).padding(.leading, 41)
                    } else {
                        Text(nick ?? message.author?.username ?? "Unknown User")
                            .foregroundColor(color)
                            .fontWeight(.semibold)
                        +
                        Text(" — \(message.timestamp.makeProperDate())")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                        +
                        Text((pronouns != nil) ? " — \(pronouns ?? "Use my name")" : "")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                        +
                        Text(message.edited_timestamp != nil ? " (edited at \(message.edited_timestamp?.makeProperHour() ?? "unknown time"))" : "")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                        textElement ?? Text(message.content)
                    }
                }
                Spacer()
                // MARK: - Quick Actions
                QuickActionsView(message: message, replyingTo: $replyingTo)
                    .if(!hovered, transform: { $0.opacity(0) } )
                    .frame(height: 10)
            }
            ForEach(message.reactions ?? [], id: \.emoji.id) { reaction in
                HStack(spacing: 4) {
                    Attachment("https://cdn.discordapp.com/emojis/\(reaction.emoji.id ?? "").png?size=16")
                        .frame(width: 16, height: 16)
                    Text(String(reaction.count))
                        .fontWeight(Font.Weight.medium)
                }
                .padding(4)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(4)
                .padding(.leading, 41)
            }
            ForEach(message.embeds ?? [], id: \.id) { embed in
                EmbedView(embed: embed).equatable()
                    .padding(.leading, 41)
            }
            ForEach(message.sticker_items ?? [], id: \.id) { sticker in
                Attachment("https://media.discordapp.net/stickers/\(sticker.id).png?size=160")
                    .frame(width: 160, height: 160)
                    .cornerRadius(3)
                    .padding(.leading, 41)
            }
            AttachmentView(media: message.attachments)
                .padding(.leading, 41)
        }
        .id(message.id)
        .onAppear {
            textQueue.async { [weak message] in
                self.load(text: message?.content ?? "")
            }
            colorQueue.async {
                if let role = role, let color = roleColors[role]?.0 {
                    let hex = String(format: "%06X", color)
                    self.color = Color.init(hex: hex)
                }
                if let role = replyRole, let color = roleColors[role]?.0 {
                    let hex = String(format: "%06X", color)
                    self.replyColor = Color.init(hex: hex)
                }
            }
        }
        .onChange(of: self.role, perform: { _ in
            colorQueue.async {
                if let role = role, let color = roleColors[role]?.0 {
                    let hex = String(format: "%06X", color)
                    withAnimation {
                        self.color = Color.init(hex: hex)
                    }
                }
                if let role = replyRole, let color = roleColors[role]?.0 {
                    let hex = String(format: "%06X", color)
                    withAnimation {
                        self.replyColor = Color.init(hex: hex)
                    }
                }
            }
        })
        .onHover { val in
            self.hovered = val
        }
    }
    func load(text: String) {
        textQueue.async {
            Markdown.markAll(text: text, ChannelMembers.shared.channelMembers[message.channel_id] ?? [:])
                .replaceError(with: Text(""))
                .sink(receiveValue: { text in
                    DispatchQueue.main.async {
                        self.textElement = text
                    }
                })
                .store(in: &bag)
        }
    }
}

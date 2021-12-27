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
    @Binding var message: Message
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
            HStack {
                if !(message.isSameAuthor()) {
                    Button(action: {
                        popup.toggle()
                    }) { [weak message] in
                        Attachment(pfpURL(message?.author?.id, message?.author?.avatar)).equatable()
                            .frame(width: 33, height: 33)
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
                        textElement ?? Text(message.content)
                    }
                }
                Spacer()
                // MARK: - Quick Actions
                QuickActionsView(message: message, replyingTo: $replyingTo)
            }
            ForEach(message.embeds ?? [], id: \.id) { embed in
                EmbedView(embed: embed).equatable()
                    .padding(.leading, 41)
            }
            AttachmentView(media: message.attachments)
                .padding(.leading, 41)
                .frame(maxWidth: 600)
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

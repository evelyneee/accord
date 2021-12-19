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

let colorQueue = DispatchQueue(label: "ColorQueue")

struct MessageCellView: View {
    @Binding var message: Message
    var nick: String?
    var replyNick: String?
    var pronouns: String?
    var replyAuthorID: String?
    var replyAuthorHash: String?
    @Binding var role: String?
    @Binding var replyRole: String?
    @Binding var replyingTo: Message?
    @State var popup: Bool = false
    @State var color: Color = Color(NSColor.textColor)
    @State var replyColor: Color = Color(NSColor.textColor)
    @State var textElement: Text? = nil
    @State var pfp: NSImage = NSImage()
    @State var replyPfp: NSImage = NSImage()
    @State var bag = Set<AnyCancellable>()
    var body: some View {
        VStack(alignment: .leading) {
            if let reply = message.referenced_message {
                HStack { [weak replyPfp] in
                    Image(nsImage: replyPfp ?? NSImage())
                        .resizable()
                        .frame(width: 15, height: 15)
                        .scaledToFit()
                        .clipShape(Circle())
                    Text(replyNick ?? reply.author?.username ?? "")
                        .foregroundColor(replyColor)
                        .fontWeight(.semibold)
                    Text(reply.content)
                        .lineLimit(0)
                }
                .padding(.leading, 47)
            }
            HStack(alignment: .top) {
                if !(message.isSameAuthor()) {
                    Button(action: {
                        popup.toggle()
                    }) { [weak pfp] in
                        Image(nsImage: pfp ?? NSImage())
                            .resizable()
                            .scaledToFit()
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
            AttachmentView(message.attachments).equatable()
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
            imageQueue.async { [weak message] in
                RequestPublisher.image(url: URL(string: pfpURL(message?.author?.id, message?.author?.avatar)))
                    .replaceError(with: NSImage())
                    .replaceNil(with: NSImage())
                    .sink { img in DispatchQueue.main.async { self.pfp = img } }
                    .store(in: &bag)
                if let replyAuthorID = replyAuthorID, let replyAuthorHash = replyAuthorHash {
                    RequestPublisher.image(url: URL(string: pfpURL(replyAuthorID, replyAuthorHash)))
                        .replaceError(with: NSImage())
                        .replaceNil(with: NSImage())
                        .sink { img in DispatchQueue.main.async { self.replyPfp = img } }
                        .store(in: &bag)
                }
            }
        }
        .onChange(of: self.role, perform: { _ in
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
        })
    }
    func load(text: String) {
        textQueue.async {
            Markdown.markAll(text: text, ChannelMembers.shared.channelMembers[message.channel_id] ?? [:])
                .assertNoFailure()
                .sink(receiveValue: { text in
                    DispatchQueue.main.async {
                        self.textElement = text
                    }
                })
                .store(in: &bag)
        }
    }
}

//
//  ChannelView.swift
//  Accord
//
//  Created by evelyn on 2020-11-27.
//

import SwiftUI
import AppKit
import AVKit

final class ChannelMembers {
    static var shared = ChannelMembers()
    var channelMembers: [String:[String:String]] = [:]
}

// MARK: - Threads

let concurrentQueue = DispatchQueue(label: "UpdatingQueue", attributes: .concurrent)
let webSocketQueue = DispatchQueue(label: "WebSocketQueue", attributes: .concurrent)

struct ChannelView: View, Equatable {

    // MARK: - Equatable protocol
    static func == (lhs: ChannelView, rhs: ChannelView) -> Bool {
        return lhs.viewModel.messages == rhs.viewModel.messages
    }

    @ObservedObject var viewModel: ChannelViewViewModel
    
    var guildID: String
    var channelID: String
    var channelName: String

    // Whether or not there is a message send in progress
    @State var sending: Bool = false

    // Nicknames/Usernames of users typing
    @State var typing: [String] = []

    // Collapsed message quick action indexes
    @State var collapsed: [Int] = []
    @State var popup: [Bool] = Array.init(repeating: false, count: 50)
    @State var sidePopups: [Bool] = Array.init(repeating: false, count: 50)

    // WebSocket error
    @State var error: String? = nil

    // Mention users in replies
    @State var mention: Bool = true
    @State var replyingTo: Message? = nil

    // Editing
    @State var editing: String? = nil
    
    @State var opened: Int? = nil
    
    // MARK: - init
    init(_ channel: Channel) {
        self.guildID = channel.guild_id ?? "@me"
        self.channelID = channel.id
        self.channelName = channel.name ?? "Unknown channel"
        self.viewModel = ChannelViewViewModel(channelID: channelID, guildID: guildID)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) { [weak viewModel] in
            Spacer()
            List {
                LazyVStack {
                    Spacer().frame(height: 90)
                    // MARK: Message loop
                    ForEach(Array(zip((viewModel?.messages ?? []).indices, viewModel?.messages ?? [])), id: \.1.id) { offset, message in
                        LazyVStack(alignment: .leading) {
                            if let reply = message.referenced_message {
                                HStack {
                                    Attachment(pfpURL(reply.author?.id, reply.author?.avatar)).equatable()
                                        .frame(width: 15, height: 15)
                                        .scaledToFit()
                                        .clipShape(Circle())
                                    if let roleColor = roleColors[(viewModel?.roles[reply.author?.id ?? ""] ?? "")] {
                                        Text(viewModel?.nicks[reply.author?.id ?? ""] ?? reply.author?.username ?? "")
                                            .foregroundColor(Color(NSColor.color(from: roleColor.0) ?? NSColor.textColor))
                                            .fontWeight(.semibold)
                                        Text(reply.content)
                                            .lineLimit(0)
                                    } else {
                                        Text(viewModel?.nicks[reply.author?.id ?? ""] ?? reply.author?.username ?? "")
                                            .fontWeight(.semibold)
                                        Text(reply.content)
                                            .lineLimit(0)
                                    }
                                }
                                .padding(.leading, 43)
                            }
                            HStack(alignment: .top) {
                                VStack {
                                    if !(message.isSameAuthor()) {
                                        Button(action: {
                                            popup[offset].toggle()
                                        }) { [weak message] in
                                            Attachment(pfpURL(message?.author?.id, message?.author?.avatar)).equatable()
                                                .frame(width: 33, height: 33)
                                                .scaledToFit()
                                                .clipShape(Circle())
                                        }
                                        .popover(isPresented: $popup[offset], content: { [weak message] in
                                            if let message = message {
                                                PopoverProfileView(user: Binding.constant(message.author))
                                            }
                                        })
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                                VStack(alignment: .leading) {
                                    if let textView = FancyTextView(text: message.content, channelID: channelID) {
                                        if message.isSameAuthor() {
                                            textView
                                                .padding(.leading, 41)
                                        } else if let authorid = message.author?.id,
                                                  let role = (viewModel?.roles[authorid] ?? ""),
                                                  let roleColor = roleColors[role]?.0 {
                                            Text(viewModel?.nicks[message.author?.id ?? ""] ?? message.author?.username ?? "Unknown User")
                                                .foregroundColor(Color(NSColor.color(from: roleColor) ?? NSColor.textColor))
                                                .fontWeight(.semibold)
                                            +
                                            Text(" — \(message.timestamp.makeProperDate())")
                                                .foregroundColor(Color.secondary)
                                                .font(.subheadline)
                                            +
                                            Text((viewModel?.pronouns[message.author?.id ?? ""] != nil) ? " — \(viewModel?.pronouns[message.author?.id ?? ""] ?? "")" : "")
                                                .foregroundColor(Color.secondary)
                                                .font(.subheadline)
                                            textView
                                        } else {
                                            Text(viewModel?.nicks[message.author?.id ?? ""] ?? message.author?.username ?? "Unknown User")
                                                .fontWeight(.semibold)
                                            +
                                            Text(" — \(message.timestamp.makeProperDate())")
                                                .foregroundColor(Color.secondary)
                                                .font(.subheadline)
                                            +
                                            Text((viewModel?.pronouns[message.author?.id ?? ""] != nil) ? " — \(viewModel?.pronouns[message.author?.id ?? ""] ?? "")" : "")
                                                .foregroundColor(Color.secondary)
                                                .font(.subheadline)
                                            textView
                                        }
                                    }
                                }

                                Spacer()
                                // MARK: - Quick Actions
                                Button(action: {
                                     sidePopups[offset].toggle()
                                 }) {
                                     Image(systemName: (sidePopups[offset] ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
                                 }
                                 .buttonStyle(BorderlessButtonStyle())
                                 if sidePopups[offset] {
                                     Button(action: { [weak message] in
                                         NSPasteboard.general.clearContents()
                                         NSPasteboard.general.setString((message?.content ?? "").marked(), forType: .string)
                                         sidePopups[offset].toggle()
                                     }) {
                                         Text("Copy")
                                     }
                                     .buttonStyle(BorderlessButtonStyle())
                                     Button(action: { [weak message] in
                                         NSPasteboard.general.clearContents()
                                         NSPasteboard.general.setString("https://discord.com/channels/\(guildID)/\(channelID)/\(message?.id ?? "")", forType: .string)
                                         sidePopups[offset].toggle()
                                     }) {
                                         Text("Copy Message Link")
                                     }
                                     .buttonStyle(BorderlessButtonStyle())
                                 }
                                 Button(action: { [weak message] in
                                     replyingTo = message
                                 }) {
                                     Image(systemName: "arrowshape.turn.up.backward.fill")
                                 }
                                 .buttonStyle(BorderlessButtonStyle())
                                 Button(action: { [weak message] in
                                     message?.delete()
                                 }) {
                                     Image(systemName: "trash")
                                 }
                                 .buttonStyle(BorderlessButtonStyle())
                            }
                            ForEach(message.embeds ?? [], id: \.id) { embed in
                                EmbedView(embed: embed).equatable()
                                    .padding(.leading, 41)
                            }

                            // MARK: - Attachments

                            if message.attachments.isEmpty == false {
                                HStack {
                                    AttachmentView(media: $viewModel.messages[offset].attachments).equatable()
                                    Spacer()
                                }
                                .padding(.leading, 41)
                            }
                        }
                        .rotationEffect(Angle(degrees: 180)).scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                    }

                    if (viewModel?.messages.isEmpty ?? false) == false {
                        headerView
                    }
                }
            }
            .rotationEffect(Angle(degrees: 180)).scaleEffect(x: -1.0, y: 1.0, anchor: .center)
            blurredTextField
        }
        .onAppear {
            // Make Gateway messages receivable now
            MessageController.shared.delegate = self
        }
        .onDisappear {
            MessageController.shared.delegate = nil
        }
    }
}

// MARK: - macOS Big Sur blur view

public struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    public init(
        material: NSVisualEffectView.Material = .contentBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = NSVisualEffectView.State.active
        return visualEffectView
    }

    public func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

// prevent index out of range
public extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

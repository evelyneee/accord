//
//  GuildView.swift
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

struct GuildView: View, Equatable {

    // MARK: - Equatable protocol
    static func == (lhs: GuildView, rhs: GuildView) -> Bool {
        return lhs.viewModel.messages == rhs.viewModel.messages
    }

    // MARK: - State-driven vars
    
    @ObservedObject var viewModel: GuildViewViewModel
    
    var guildID: String
    var channelID: String
    var channelName: String
    @State var chatTextFieldContents: String = ""

    // Whether or not there is a message send in progress
    @State var sending: Bool = false

    // Nicknames/Usernames of users typing
    @State var typing: [String] = []

    // Collapsed message quick action indexes
    @State var collapsed: [Int] = []
    @State var pfpArray: [String:NSImage] = [:]

    // TODO: Add user popup view, done properly
    @State var poppedUpUserProfile: Bool = false
    @State var userPoppedUp: Int? = nil
    @State var popup: [Bool] = Array.init(repeating: false, count: 50)

    // WebSocket error
    @State var error: String? = nil

    // Mention users in replies
    @State var mention: Bool = true
    @State var replyingTo: Message? = nil

    // Editing
    @State var editing: String? = nil
    
    @State var opened: Int? = nil
    
    init(guildID: String, channelID: String, channelName: String? = nil) {
        self.guildID = guildID
        self.channelID = channelID
        self.channelName = channelName ?? "Unknown channel"
        self.viewModel = GuildViewViewModel(channelID: channelID, guildID: guildID)
    }
    
    // MARK: - View body begins here
    var body: some View {
        ZStack(alignment: .topTrailing) { [weak viewModel] in
            ZStack(alignment: .bottom) {
                Spacer()
                List {
                    LazyVStack {
                        Spacer().frame(height: 93)
                        // MARK: Message loop
                        ForEach(Array(zip((viewModel?.messages ?? []).indices, viewModel?.messages ?? [])), id: \.1.id) { offset, message in
                            LazyVStack(alignment: .leading) {
                                // MARK: - Reply
                                if let reply = message.referenced_message {
                                    makeReplyView(reply: reply)
                                }
                                // MARK: - The actual message
                                HStack(alignment: .top) {
                                    VStack {
                                        if !(message.isSameAuthor()) {
                                            Button(action: {
                                                popup[offset].toggle()
                                            }) { [weak message] in
                                                Image(nsImage: NSImage(data: message?.author?.pfp ?? Data()) ?? NSImage()).resizable()
                                                    .frame(width: 33, height: 33)
                                                    .scaledToFit()
                                                    .clipShape(Circle())
                                            }
                                            .popover(isPresented: $popup[offset], content: {
                                                 PopoverProfileView(user: Binding.constant(message.author))
                                            })
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                    }
                                    if let author = message.author?.username {
                                        VStack(alignment: .leading) {
                                            if let textView = FancyTextView(text: $viewModel.messages[offset].content, channelID: Binding.constant(channelID)) {
                                                if message.isSameAuthor() {
                                                    textView
                                                        .padding(.leading, 41)
                                                } else if viewModel!.roles.isEmpty {
                                                    Text(viewModel!.nicks[message.author?.id ?? ""] ?? author)
                                                        .fontWeight(.semibold)
                                                    textView
                                                } else {
                                                    if let roleColor = roleColors[(viewModel!.roles[message.author?.id ?? ""] ?? "")]?.0 {
                                                        Text(viewModel!.nicks[message.author?.id ?? ""] ?? author)
                                                            .foregroundColor(Color(NSColor.color(from: roleColor) ?? NSColor.textColor))
                                                            .fontWeight(.semibold)
                                                        textView
                                                    } else {
                                                        Text(viewModel!.nicks[message.author?.id ?? ""] ?? author)
                                                            .fontWeight(.semibold)
                                                        textView
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Spacer()
                                    // MARK: - Quick Actions
                                    Button(action: {
                                        if opened == offset {
                                            opened = nil
                                        } else {
                                            opened = offset
                                        }
                                    }) {
                                        Image(systemName: ((opened == offset) ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    if (opened == offset) {
                                        Button(action: { [weak message] in
                                            let clipQueue = DispatchQueue(label: "clipboard")
                                            clipQueue.async {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString((message?.content ?? "").marked(), forType: .string)
                                            }
                                            opened = nil
                                        }) {
                                            Text("Copy")
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        Button(action: { [weak message] in
                                            DispatchQueue.global().async {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString("https://discord.com/channels/\(guildID)/\(channelID)/\(message?.id ?? "")", forType: .string)
                                                opened = nil
                                            }
                                        }) {
                                            Text("Copy Message Link")
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    Button(action: { [weak message] in
                                        DispatchQueue.main.async {
                                            replyingTo = message
                                        }
                                    }) {
                                        Image(systemName: "arrowshape.turn.up.backward.fill")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    /*
                                    Button(action: { [weak message] in
                                        editing = message?.id
                                        chatTextFieldContents = ""
                                    }) {
                                        Image(systemName: "pencil")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())

                                     */
                                    Button(action: { [weak message] in
                                        message!.delete()
                                    }) {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                ForEach(message.embeds ?? [], id: \.id) { embed in
                                    EmbedView(embed).equatable()
                                        .padding(.leading, (message.isSameAuthor() ? 0 : 41))
                                }

                                // MARK: - Attachments

                                if message.attachments.isEmpty == false {
                                    HStack {
                                        AttachmentView(media: $viewModel.messages[offset].attachments).equatable()
                                        Spacer()
                                    }
                                    .frame(maxWidth: 400, maxHeight: 300)
                                    .padding(.leading, 41)
                                }
                            }
                            .id(message.id)
                            .rotationEffect(.radians(.pi))
                            .scaleEffect(x: -1, y: 1, anchor: .center)
                        }

                        if (viewModel?.messages.isEmpty ?? false) == false {
                            headerView
                        }
                    }
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                blurredTextField
            }
            .onAppear {
                // MARK: - Making WebSocket messages receivable now, begin load
                MessageController.shared.delegate = self
            }
            // MARK: - WebSocket error display
            if let error = error {
                VStack(alignment: .leading) {
                    Text("WebSocket was disconnected")
                        .fontWeight(.bold)
                    Text("Cause: \(error)")
                }
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                .padding()
            }
        }
    }
}

extension GuildView {
    func makeReplyView(reply: Reply) -> some View {
        return HStack {
            Spacer().frame(width: 50)
            Image(nsImage: NSImage(data: reply.author?.pfp ?? Data()) ?? NSImage()).resizable()
                .frame(width: 15, height: 15)
                .scaledToFit()
                .clipShape(Circle())
            if let roleColor = roleColors[(viewModel.roles[reply.author?.id ?? ""] ?? "")] {
                Text(viewModel.nicks[reply.author?.id ?? ""] ?? reply.author?.username ?? "")
                    .foregroundColor(Color(NSColor.color(from: roleColor.0) ?? NSColor.textColor))
                    .fontWeight(.semibold)
                if #available(macOS 12.0, *) {
                    Text(try! AttributedString(markdown: reply.content))
                        .lineLimit(0)
                } else {
                    Text(reply.content)
                        .lineLimit(0)
                }
            } else {
                Text(viewModel.nicks[reply.author?.id ?? ""] ?? reply.author?.username ?? "")
                    .fontWeight(.semibold)
                if #available(macOS 12.0, *) {
                    Text(try! AttributedString(markdown: reply.content))
                        .lineLimit(0)
                } else {
                    Text(reply.content)
                        .lineLimit(0)
                }
            }
        }

    }
}

// MARK: - macOS Big Sur blur view

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = NSVisualEffectView.State.active
        visualEffectView.shadow?.shadowBlurRadius = 20
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

// MARK: - Multi window

func showWindow(guildID: String, channelID: String, channelName: String) {
    var windowRef: NSWindow
    windowRef = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
        backing: .buffered, defer: false
    )
    windowRef.contentView = NSHostingView(rootView: GuildView(guildID: guildID, channelID: channelID, channelName: channelName))
    windowRef.minSize = NSSize(width: 500, height: 300)
    windowRef.isReleasedWhenClosed = false
    windowRef.title = "\(channelName) - Accord"
    windowRef.makeKeyAndOrderFront(nil)
}

// prevent index out of range

public extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

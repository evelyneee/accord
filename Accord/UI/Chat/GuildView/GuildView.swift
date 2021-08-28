//
//  GuildView.swift
//  Accord
//
//  Created by evelyn on 2020-11-27.
//

import SwiftUI
import AppKit
import AVKit

// styles and structs and vars

final class ChannelMembers {
    static var shared = ChannelMembers()
    var channelMembers: [String:[String:String]] = [:]
}

struct CoolButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CGFloat(0.85) : 1.0)
            .rotationEffect(.degrees(configuration.isPressed ? 0.0 : 0))
            .blur(radius: configuration.isPressed ? CGFloat(0.0) : 0)
            .animation(Animation.spring(response: 0.35, dampingFraction: 0.35, blendDuration: 1))
            .padding(.bottom, 3)
    }
}

// the messaging view concept

let concurrentQueue = DispatchQueue(label: "UpdatingQueue", attributes: .concurrent)
let secondLoadQueue = DispatchQueue(label: "SecondLoadQueue", attributes: .concurrent)
let webSocketQueue = DispatchQueue(label: "WebSocketQueue", attributes: .concurrent)

let net = NetworkHandling()

struct GuildView: View, Equatable {
    
    // MARK: - Equatable protocol
    static func == (lhs: GuildView, rhs: GuildView) -> Bool {
        return lhs.data == rhs.data
    }
    
    // MARK: - State-driven vars
    @Binding var guildID: String
    @Binding var channelID: String
    @Binding var channelName: String
    @State var chatTextFieldContents: String = ""
    /// The actual message array.
    @State var data = [Message]()
    // Whether or not there is a message send in progress
    @State var sending: Bool = false
    // Nicknames/Usernames of users typing
    @State var typing: [String] = []
    // Collapsed message quick action indexes
    @State var collapsed: [Int] = []
    @State var pfpArray: [String:NSImage] = [:]
    // nicks and roles
    @State var nicks: [String:String] = [:]
    @State var roles: [String:[String]] = [:]
    // TODO: Add user popup view, done properly
    @State var poppedUpUserProfile: Bool = false
    @State var userPoppedUp: Int? = nil
    // WebSocket error
    @State var error: String? = nil
    // Mention users in replies
    @State var mention: Bool = true
    @State var replyingTo: Message? = nil
    
    // MARK: - View body begins here
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottom) {
                Spacer()
                List {
                    LazyVStack {
                        Spacer().frame(height: 93)
                        // MARK: Sending animation
                        if (sending) && chatTextFieldContents != "" {
                            sendingView
                        }
                        // MARK: Message loop
                        ForEach(Array(data), id: \.id) { message in
                            /// get index of message (fixes the index out of range)
                            
                            if let offset = data.firstIndex(of: message) {
                                if data.contains(data[offset]) {
                                    LazyVStack(alignment: .leading) {
                                        // MARK: - Reply
                                        if let reply = message.referenced_message {
                                            HStack {
                                                Spacer().frame(width: 50)
                                                Image(nsImage: NSImage(data: reply.author?.pfp ?? Data()) ?? NSImage()).resizable()
                                                    .scaledToFit()
                                                    .frame(width: 15, height: 15)
                                                    .clipShape(Circle())

                                                if let roleColor = roleColors[(roles[reply.author?.id ?? "fuck"] ?? ["fucjk"])[safe: 0] ?? "f"] {
                                                    Text(nicks[reply.author?.id ?? ""] ?? reply.author?.username ?? "")
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
                                                    Text(nicks[reply.author?.id ?? ""] ?? reply.author?.username ?? "")
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
                                        // MARK: - The actual message
                                        HStack(alignment: .top) {
                                            VStack {
                                                if (message.author?.username ?? "" != (data[safe: Int(offset + 1)]?.author?.username ?? "")) {

                                                    Button(action: { [weak message] in
                                                        poppedUpUserProfile.toggle()
                                                        userPoppedUp = offset
                                                    }) {
                                                        Image(nsImage: NSImage(data: message.author?.pfp ?? Data()) ?? NSImage()).resizable()
                                                            .scaledToFit()
                                                            .frame(width: (pfpShown ? 33 : 15), height: (pfpShown ? 33 : 15))
                                                            .padding(.horizontal, 5)
                                                            .clipShape(Circle())

                                                    }
                                                    .buttonStyle(BorderlessButtonStyle())
//                                                    .popover(isPresented: Binding.constant(true), content: {
//                                                        if (userPoppedUp ?? 0 == offset) {
//                                                            PopoverProfileView(user: Binding.constant(message.author!))
//                                                        }
//                                                    })
                                                }
                                            }
                                            if let author = message.author?.username {
                                                VStack(alignment: .leading) {
                                                    if offset != (data.count - 1) {
                                                        if author == (data[Int(offset + 1)].author?.username ?? "") {
                                                            FancyTextView(text: $data[offset].content, channelID: $channelID)
                                                                .padding(.leading, 51)
                                                        } else if roles.isEmpty {
                                                            Text(nicks[message.author?.id ?? ""] ?? author)
                                                                .fontWeight(.semibold)
                                                            FancyTextView(text: $data[offset].content, channelID: $channelID)
                                                        } else {
                                                            if let roleColor = roleColors[(roles[message.author?.id ?? "fuck"] ?? ["fucjk"])[safe: 0] ?? "f"] {
                                                                Text(nicks[message.author?.id ?? ""] ?? author)
                                                                    .foregroundColor(Color(NSColor.color(from: roleColor.0) ?? NSColor.textColor))
                                                                    .fontWeight(.semibold)
                                                                FancyTextView(text: $data[offset].content, channelID: $channelID)
                                                            } else {
                                                                Text(nicks[message.author?.id ?? ""] ?? author)
                                                                    .fontWeight(.semibold)
                                                                FancyTextView(text: $data[offset].content, channelID: $channelID)
                                                            }
                                                        }
                                                    } else {
                                                        if roles.isEmpty {
                                                            Text(nicks[message.author?.id ?? ""] ?? author)
                                                                .fontWeight(.semibold)
                                                            FancyTextView(text: $data[offset].content, channelID: $channelID)
                                                        } else if let roleColor = roleColors[(roles[message.author?.id ?? ""] ?? [])[safe: 0] ?? ""]?.0 {
                                                            Text(nicks[message.author?.id ?? ""] ?? author)
                                                                .foregroundColor(Color(NSColor.color(from: roleColor) ?? NSColor.textColor))
                                                                .fontWeight(.semibold)
                                                            FancyTextView(text: $data[offset].content, channelID: $channelID)
                                                        } else {
                                                            Text(nicks[message.author?.id ?? ""] ?? author)
                                                                .fontWeight(.semibold)
                                                            FancyTextView(text: $data[offset].content, channelID: $channelID)
                                                        }
                                                    }

                                                }
                                            }
                                            Spacer()
                                            // MARK: - Quick Actions
                                            Button(action: {
                                                if collapsed.contains(offset) {
                                                    collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                                                } else {
                                                    collapsed.append(offset)
                                                }
                                            }) {
                                                Image(systemName: ((collapsed.contains(offset)) ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            if (collapsed.contains(offset)) {
                                                Button(action: { [weak message] in
                                                    DispatchQueue.main.async {
                                                        NSPasteboard.general.clearContents()
                                                        NSPasteboard.general.setString(message?.content ?? "", forType: .string)
                                                        if collapsed.contains(offset) {
                                                            collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                                                        } else {
                                                            collapsed.append(offset)
                                                        }
                                                    }
                                                }) {
                                                    Text("Copy")
                                                }
                                                .buttonStyle(BorderlessButtonStyle())
                                                Button(action: { [weak message] in
                                                    DispatchQueue.main.async {
                                                        NSPasteboard.general.clearContents()
                                                        NSPasteboard.general.setString("https://discord.com/channels/\(guildID)/\(channelID)/\(message?.id ?? "")", forType: .string)
                                                        if collapsed.contains(offset) {
                                                            collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                                                        } else {
                                                            collapsed.append(offset)
                                                        }
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
                                            Button(action: { [weak message] in
                                                message!.delete()
                                            }) {
                                                Image(systemName: "trash")
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                        // MARK: - Attachments
                                        if message.attachments.isEmpty == false {
                                            HStack {
                                                AttachmentView(media: $data[offset].attachments)
                                                Spacer()
                                            }
                                            .frame(maxWidth: 400, maxHeight: 300)
                                            .padding(.leading, 52)
                                        }
                                    }
                                    .id(message.id)
                                    .rotationEffect(.radians(.pi))
                                    .scaleEffect(x: -1, y: 1, anchor: .center)
                                }
                            }


                        }
                        if data.isEmpty == false {
                            headerView
                        }
                    }
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                blurredTextField
            }
            .onAppear {
                if AccordCoreVars.shared.token != "" {
                    concurrentQueue.async {
                        NetworkHandling.shared?.requestData(url: "\(rootURL)/channels/\(channelID)/messages?limit=50", token: AccordCoreVars.shared.token, json: true, type: .GET, bodyObject: [:]) { success, rawData in
                            if success == true {
                                // MARK: Channel setup after messages loaded.
                                do {
                                    data = try JSONDecoder().decode([Message].self, from: rawData!)
                                    // MARK: Making WebSocket messages receivable now
                                    MessageController.shared.delegate = self
                                    secondLoadQueue.async {
                                        performSecondStageLoad()
                                    }
                                } catch {
                                }
                            }
                        }
                    }
                }
            }
            // MARK: WebSocket error display
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

func showWindow(guildID: String, channelID: String, channelName: String) {
    var windowRef: NSWindow
    windowRef = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
        backing: .buffered, defer: false)
    windowRef.contentView = NSHostingView(rootView: GuildView(guildID: Binding.constant(guildID), channelID: Binding.constant(channelID), channelName: Binding.constant(channelName)))
    windowRef.minSize = NSSize(width: 500, height: 300)
    windowRef.isReleasedWhenClosed = false
    windowRef.title = "\(channelName) - Accord"
    windowRef.makeKeyAndOrderFront(nil)
}

public extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

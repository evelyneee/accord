//
//  ChannelView.swift
//  Accord
//
//  Created by evelyn on 2020-11-27.
//

import AppKit
import AVKit
import SwiftUI
import Combine

struct ChannelView: View, Equatable {
    
    static func == (lhs: ChannelView, rhs: ChannelView) -> Bool {
        return lhs.viewModel == rhs.viewModel
    }

    @StateObject var viewModel: ChannelViewViewModel

    var guildID: String
    var channelID: String
    var channelName: String
    var guildName: String

    // Whether or not there is a message send in progress
    @State var sending: Bool = false

    // Nicknames/Usernames of users typing
    @State var typing: [String] = []

    // WebSocket error
    @State var error: String?

    // Mention users in replies
    @State var mention: Bool = true
    @State var replyingTo: Message?

    @State var pins: Bool = false
    @State var mentions: Bool = false

    @State var memberListShown: Bool = false
    @State var memberList: [OPSItems] = .init()
    @State var fileUpload: Data?
    @State var fileUploadURL: URL?
        
    @AppStorage("MetalRenderer")
    var metalRenderer: Bool = false

    @State private var cancellable = Set<AnyCancellable>()
    
    // MARK: - init
    init(_ channel: Channel, _ guildName: String? = nil) {
        guildID = channel.guild_id ?? "@me"
        channelID = channel.id
        channelName = channel.name ?? channel.recipients?.first?.username ?? "Unknown channel"
        self.guildName = guildName ?? "Direct Messages"
        _viewModel = StateObject(wrappedValue: ChannelViewViewModel(channelID: channel.id, guildID: channel.guild_id ?? "@me"))
        if DiscordDesktopRPCEnabled {
            DiscordDesktopRPC.update(guildName: channel.guild_name, channelName: channel.computedName)
        }
    }

    var messagesView: some View {
        ForEach(viewModel.messages, id: \.identifier) { message in
            if let author = message.author {
                MessageCellView (
                    message: message,
                    nick: viewModel.nicks[author.id],
                    replyNick: viewModel.nicks[message.referenced_message?.author?.id ?? ""],
                    pronouns: viewModel.pronouns[author.id],
                    avatar: viewModel.avatars[author.id],
                    guildID: guildID,
                    role: $viewModel.roles[author.id],
                    replyRole: $viewModel.roles[message.referenced_message?.author?.id ?? ""],
                    replyingTo: $replyingTo
                )
                .equatable()
                .id(message.identifier)
                .listRowInsets(.init(top: 0, leading: 0, bottom: (message.isSameAuthor && message.referenced_message == nil) ? 0.5 : 10, trailing: 0))
                .if(message.mentions.compactMap({ $0?.id }).contains(user_id), transform: {
                    $0
                        .padding(5)
                        .frame (
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .background(Color.yellow.opacity(0.05))
                        .cornerRadius(7)
                })
                .onAppear {
                    if viewModel.messages.count >= 50 &&
                        message == viewModel.messages[viewModel.messages.count - 2] {
                        messageFetchQueue.async {
                            viewModel.loadMoreMessages()
                        }
                    }
                }
            }
        }
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
    }
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottom) {
                List {
                    Spacer().frame(height: typing.isEmpty && replyingTo == nil ? 65 : 75)
                    if metalRenderer {
                        messagesView.drawingGroup()
                    } else {
                        messagesView
                    }
                }
                .rotationEffect(.init(degrees: 180))
                .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                blurredTextField
            }
            if memberListShown {
                MemberListView(list: $memberList)
                    .frame(width: 250)
                    .onAppear {
                        if memberList.isEmpty {
                            try? wss.memberList(for: guildID, in: channelID)
                        }
                    }
            }
        }
        .navigationTitle(Text("\(guildID == "@me" ? "" : "#")\(channelName)"))
        .navigationSubtitle(Text(guildName))
        .presentedWindowToolbarStyle(.unifiedCompact)
        .onAppear {
            guard wss != nil else { return MentionSender.shared.deselect() }
            wss.typingSubject
                .receive(on: webSocketQueue)
                .sink { [weak viewModel] msg, channelID in
                    guard channelID == self.channelID else { return }
                    guard let memberDecodable = try? JSONDecoder().decode(TypingEvent.self, from: msg).d,
                          memberDecodable.user_id != AccordCoreVars.user?.id else { return }
                    let isKnownAs = viewModel?.nicks[memberDecodable.user_id] ?? memberDecodable.member?.nick ?? memberDecodable.member?.user.username ?? "Unknown User"
                    if !(typing.contains(isKnownAs)) {
                        typing.append(isKnownAs)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        guard !(typing.isEmpty) else { return }
                        typing.removeLast()
                    }
                }
                .store(in: &cancellable)
            wss.memberListSubject
                .sink { list in
                    if self.memberListShown, memberList.isEmpty {
                        self.memberList = Array(list.d.ops.compactMap(\.items).joined())
                    }
                }
                .store(in: &cancellable)
        }
        .onDrop(of: ["public.file-url"], isTargeted: Binding.constant(false)) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { data, _ in
                if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                    fileUpload = try! Data(contentsOf: url)
                    fileUploadURL = url
                }
            })
            return true
        }
        .toolbar {
            ToolbarItemGroup {
                Toggle(isOn: $pins) {
                    Image(systemName: "pin.fill")
                        .rotationEffect(.degrees(45))
                }
                .sheet(isPresented: $pins) {
                    PinsView(guildID: guildID, channelID: channelID, replyingTo: Binding.constant(nil))
                        .frame(width: 500, height: 600)
                }
                Toggle(isOn: $mentions) {
                    Image(systemName: "bell.badge.fill")
                }
                .sheet(isPresented: $mentions) {
                    MentionsView(replyingTo: Binding.constant(nil))
                        .frame(width: 500, height: 600)
                }
                if guildID != "@me" {
                    Toggle(isOn: $memberListShown.animation()) {
                        Image(systemName: "person.2.fill")
                    }
                }
            }
        }
        .onDisappear {
            self.cancellable.forEach { $0.cancel() }
            self.cancellable.removeAll()
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

    public func makeNSView(context _: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = NSVisualEffectView.State.active
        return visualEffectView
    }

    public func updateNSView(_ visualEffectView: NSVisualEffectView, context _: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct MemberListView: View {
    @Binding var list: [OPSItems]
    var body: some View {
        List(list.compactMap(\.member), id: \.user.id) { ops in
            HStack {
                Attachment(pfpURL(ops.user.id, ops.user.avatar, discriminator: ops.user.discriminator, "24"))
                    .equatable()
                    .frame(width: 33, height: 33)
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text(ops.nick ?? ops.user.username)
                        .fontWeight(.medium)
                        .lineLimit(0)
                    if let presence = ops.presence?.activities.first?.state {
                        Text(presence).foregroundColor(.secondary)
                            .lineLimit(0)
                    }
                }
            }
        }
    }
}

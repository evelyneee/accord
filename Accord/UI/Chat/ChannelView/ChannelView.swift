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
    var channelMembers: [String: [String: String]] = [:]
}

struct ChannelView: View, Equatable {

    // MARK: - Equatable protocol
    static func == (lhs: ChannelView, rhs: ChannelView) -> Bool {
        return lhs.viewModel.messages == rhs.viewModel.messages
    }

    @ObservedObject var viewModel: ChannelViewViewModel

    var guildID: String
    var channelID: String
    var channelName: String
    var guildName: String

    // Whether or not there is a message send in progress
    @State var sending: Bool = false

    // Nicknames/Usernames of users typing
    @State var typing: [String] = []

    // Collapsed message quick action indexes

    // WebSocket error
    @State var error: String?

    // Mention users in replies
    @State var mention: Bool = true
    @State var replyingTo: Message?

    @State var pins: Bool = false
    @State var mentions: Bool = false

    var messageMap: [String: Int?] {
        return viewModel.messages.enumerated().compactMap { (index, element) in
            return [element.id: index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
    }
    
    @State var memberListShown: Bool = false
    @State var memberList = [OPSItems]()
    
    // MARK: - init
    init(_ channel: Channel, _ guildName: String? = nil) {
        self.guildID = channel.guild_id ?? "@me"
        self.channelID = channel.id
        self.channelName = channel.name ?? channel.recipients?[safe: 0]?.username ?? "Unknown channel"
        self.guildName = guildName ?? "Direct Messages"
        self.viewModel = ChannelViewViewModel(channelID: channelID, guildID: guildID)
        if DiscordDesktopRPCEnabled {
            DiscordDesktopRPC.update(guildName: channel.guild_name, channelName: channel.computedName)
        }
    }

    var body: some View {
        HStack {
            ZStack(alignment: .bottom) { [weak viewModel] in
                List {
                    ForEach($viewModel.messages, id: \.identifier) { $message in
                        MessageCellView(message: message, nick: viewModel?.nicks[message.author?.id ?? ""], replyNick: viewModel?.nicks[message.referenced_message?.author?.id ?? ""], pronouns: viewModel?.pronouns[message.author?.id ?? ""], role: $viewModel.roles[message.author?.id ?? ""], replyRole: $viewModel.roles[message.referenced_message?.author?.id ?? ""], replyingTo: $replyingTo)
                    }
                    Spacer().frame(height: 90)
                }
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
        .presentedWindowToolbarStyle(UnifiedCompactWindowToolbarStyle())
        .onAppear {
            wss.typingSubject
                .sink { msg, channelID in
                    guard channelID == self.channelID else { return }
                    webSocketQueue.async { [weak viewModel] in
                        guard let memberDecodable = try? JSONDecoder().decode(TypingEvent.self, from: msg).d else { return }
                        let isKnownAs = viewModel?.nicks[memberDecodable.user_id] ?? memberDecodable.member.nick ?? memberDecodable.member.user.username
                        if !(typing.contains(isKnownAs)) {
                            typing.append(isKnownAs)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                            guard !(typing.isEmpty) else { return }
                            typing.removeLast()
                        })
                    }
                }
                .store(in: &viewModel.cancellable)
            wss.memberListSubject
                .sink { list in
                    if self.memberListShown, memberList.isEmpty {
                        self.memberList = Array(list.d.ops.compactMap { $0.items }.joined())
                    }
                }
                .store(in: &viewModel.cancellable)
        }
        .onDisappear { [weak viewModel] in
            viewModel?.cancellable.invalidateAll()
        }
        .toolbar {
            ToolbarItemGroup {
                Toggle(isOn: Binding.constant(false)) {
                    Image(systemName: "pin.fill")
                }
                .hidden()
                /*
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
                .popover(isPresented: $mentions) {
                    MentionsView(replyingTo: Binding.constant(nil))
                        .frame(width: 500, height: 600)
                }
                if guildID != "@me" {
                    Toggle(isOn: $memberListShown.animation()) {
                        Image(systemName: "sidebar.right")
                    }
                }
                 */
            }
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

struct MemberListView: View {
    @Binding var list: [OPSItems]
    var body: some View {
        List(list.compactMap { $0.member }, id: \.user.id) { ops in
            HStack {
                Attachment(pfpURL(ops.user.id, ops.user.avatar, "24"))
                    .frame(width: 33, height: 33)
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text(ops.nick ?? ops.user.username)
                        .fontWeight(.medium)
                        .lineLimit(0)
                    if let presence = ops.presence?.activities[safe: 0]?.state {
                        Text(presence).foregroundColor(.secondary)
                            .lineLimit(0)
                    }
                }
            }
        }
    }
}

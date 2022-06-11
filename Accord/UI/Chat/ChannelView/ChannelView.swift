//
//  ChannelView.swift
//  Accord
//
//  Created by evelyn on 2020-11-27.
//

import AppKit
import AVKit
import Combine
import SwiftUI

struct ChannelView: View, Equatable {
    static func == (lhs: ChannelView, rhs: ChannelView) -> Bool {
        lhs.viewModel == rhs.viewModel
    }

    @StateObject var viewModel: ChannelViewViewModel

    var guildID: String
    var channelID: String
    var channelName: String
    var guildName: String

    // Whether or not there is a message send in progress
    @State var sending: Bool = false

    // WebSocket error
    @State var error: String?

    // Mention users in replies
    @State var mention: Bool = true
    @State var replyingTo: Message?
    @State var mentionUser: Bool = true

    @State var pins: Bool = false
    @State var mentions: Bool = false

    @AppStorage("memberListShown")
    var memberListShown: Bool = false

    @State var fileUpload: Data?
    @State var fileUploadURL: URL?

    @AppStorage("MetalRenderer")
    var metalRenderer: Bool = false

    @State private var cancellable = Set<AnyCancellable>()

    @Environment(\.user)
    var user: User

    @Environment(\.colorScheme)
    var colorScheme: ColorScheme

    static var scrollTo = PassthroughSubject<String, Never>()

    // MARK: - init

    init(_ channel: Channel, _ guildName: String? = nil) {
        guildID = channel.guild_id ?? "@me"
        channelID = channel.id
        channelName = channel.name ?? channel.recipients?.first?.username ?? "Unknown channel"
        self.guildName = guildName ?? "Direct Messages"
        _viewModel = StateObject(wrappedValue: ChannelViewViewModel(channel: channel))
        viewModel.memberList = channel.recipients?.map(OPSItems.init) ?? []
        if wss.connection?.state == .cancelled {
            concurrentQueue.async {
                wss?.reset()
            }
        }
    }

    var messagesView: some View {
        ForEach(viewModel.messages, id: \.identifier) { message in
            MessageCellView(
                message: message,
                nick: viewModel.nicks[message.author?.id ?? ""],
                replyNick: viewModel.nicks[message.referenced_message?.author?.id ?? ""],
                pronouns: viewModel.pronouns[message.author?.id ?? ""],
                avatar: viewModel.avatars[message.author?.id ?? ""],
                guildID: viewModel.guildID,
                permissions: $viewModel.permissions,
                role: $viewModel.roles[message.author?.id ?? ""],
                replyRole: $viewModel.roles[message.referenced_message?.author?.id ?? ""],
                replyingTo: $replyingTo
            )
            .equatable()
            .id(message.id)
            .listRowInsets(EdgeInsets(
                top: 3.5,
                leading: 0,
                bottom: message.bottomInset,
                trailing: 0
            ))
            .padding(.horizontal, 5.0)
            .padding(.vertical, message.userMentioned ? 3.0 : 0.0)
            .background(message.userMentioned ? Color.yellow.opacity(0.1).cornerRadius(7) : nil)
            .onAppear { [unowned viewModel] in
                if viewModel.messages.count >= 50,
                   message == viewModel.messages[viewModel.messages.count - 2]
                {
                    messageFetchQueue.async {
                        viewModel.loadMoreMessages()
                    }
                }
            }
        }
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
        .fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        HStack(content: {
            VStack(spacing: 0) {
                List {
                    Spacer().frame(height: 15)
                    if metalRenderer {
                        messagesView
                            .drawingGroup()
                    } else {
                        messagesView
                    }
                }
                .listRowBackground(colorScheme == .dark ? Color.darkListBackground : Color(NSColor.controlBackgroundColor))
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                blurredTextField
            }
            if memberListShown {
                MemberListView(guildID: viewModel.guildID, list: $viewModel.memberList)
                    .frame(width: 250)
                    .onAppear { [unowned viewModel] in
                        if viewModel.memberList.isEmpty, viewModel.guildID != "@me" {
                            try? wss.memberList(for: viewModel.guildID, in: viewModel.channelID)
                        }
                    }
            }
        })
        .navigationTitle(Text("\(viewModel.guildID == "@me" ? "" : "#")\(channelName)"))
        .navigationSubtitle(Text(guildName))
        .presentedWindowToolbarStyle(.unifiedCompact)
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
                .popover(isPresented: $pins) { [unowned viewModel] in
                    PinsView(guildID: viewModel.guildID, channelID: viewModel.channelID, replyingTo: Binding.constant(nil))
                        .frame(width: 500, height: 600)
                }
                Toggle(isOn: $mentions) {
                    Image(systemName: "bell.badge.fill")
                }
                .popover(isPresented: $mentions) {
                    MentionsView(replyingTo: Binding.constant(nil))
                        .frame(width: 500, height: 600)
                }
                Toggle(isOn: $memberListShown.animation()) {
                    Image(systemName: "person.2.fill")
                }
            }
        }
    }
}

struct MemberListView: View {
    var guildID: String
    @Binding var list: [OPSItems]
    var body: some View {
        List(self.$list, id: \.id) { $ops in
            if let group = ops.group {
                Text(
                    "\(group.id == "offline" ? "Offline" : group.id == "online" ? "Online" : roleNames[group.id ?? ""] ?? "") - \(group.count ?? 0)"
                )
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding([.top])
            } else {
                MemberListViewCell(guildID: self.guildID, ops: $ops)
            }
        }
    }
}

struct MemberListViewCell: View {
    var guildID: String
    @Binding var ops: OPSItems
    @State var popup: Bool = false
    var body: some View {
        Button(action: {
            self.popup.toggle()
        }) { [unowned ops] in
            HStack {
                Attachment(pfpURL(ops.member?.user.id ?? "", ops.member?.user.avatar ?? "", discriminator: ops.member?.user.discriminator ?? "", "24"))
                    .equatable()
                    .frame(width: 33, height: 33)
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text(ops.member?.nick ?? ops.member?.user.username ?? "")
                        .fontWeight(.medium)
                        .foregroundColor({ () -> Color in
                            if let role = ops.member?.roles?.first, let color = roleColors[role]?.0 {
                                return Color(int: color)
                            }
                            return Color.primary
                        }())
                        .lineLimit(0)
                    if let presence = ops.member?.presence?.activities.first?.state {
                        Text(presence).foregroundColor(.secondary)
                            .lineLimit(0)
                    }
                }
            }
        }
        .buttonStyle(.borderless)
        .popover(isPresented: self.$popup, content: {
            PopoverProfileView(user: ops.member?.user, guildID: guildID)
        })
    }
}

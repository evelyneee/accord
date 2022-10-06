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

private struct ChannelIDKey: EnvironmentKey {
    static let defaultValue = ""
}

private struct GuildIDKey: EnvironmentKey {
    static let defaultValue = ""
}

extension EnvironmentValues {
    var channelID: String {
        get { self[ChannelIDKey.self] }
        set { self[ChannelIDKey.self] = newValue }
    }
    var guildID: String {
        get { self[GuildIDKey.self] }
        set { self[GuildIDKey.self] = newValue }
    }
}

extension View {
    func channelProperties(channelID: String, guildID: String) -> some View {
        self
            .environment(\.channelID, channelID)
            .environment(\.guildID, guildID)
    }
}

struct MessagePlaceholders: View {
    var body : some View {
        ForEach(1..<20) { _ in
            let prefix = Int.random(in: 5...20)
            let words = Int.random(in: 1...6)
            VStack {
                HStack(alignment: .bottom) {
                    Circle()
                        .frame(width: 35, height: 35)
                        .padding(.trailing, 1.5)
                        .fixedSize()
                    
                    VStack(alignment: .leading) {
                        Text(UUID().uuidString.prefix(prefix).stringLiteral)
                            .font(.chatTextFont)
                        Text((0..<words).map { _ in UUID().uuidString }.joined(separator: " "))
                            .font(.chatTextFont)
                        Spacer().frame(height: 1.3)
                    }
                }
                .foregroundColor(.secondary.opacity(0.4))
                Spacer()
            }
            .redacted(reason: .placeholder)
        }
    }
}

struct ChannelView: View, Equatable {
    static func == (lhs: ChannelView, rhs: ChannelView) -> Bool {
        lhs.viewModel == rhs.viewModel
    }

    @StateObject var viewModel: ChannelViewViewModel
    
    var channelName: String {
        channel.name ?? channel.recipients?.first?.username ?? "Unknown channel"
    }
    
    var guildName: String
    
    @Binding var channel: Channel

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
    
    @State var searchText: String = ""
    @State var showSearch: Bool = false
    @State var searchMessages: [Message] = []
    @State var searchForPinnedMessages: Bool = false
    
    @AppStorage("memberListShown")
    var memberListShown: Bool = false

    @State var fileUploads: [(Data?, URL?)] = .init()

    @AppStorage("MetalRenderer")
    var metalRenderer: Bool = false

    @State private var cancellable = Set<AnyCancellable>()

    @Environment(\.user)
    var user: User

    @Environment(\.colorScheme)
    var colorScheme: ColorScheme

    static var scrollTo = PassthroughSubject<(String, String), Never>()
    
    @State var scrolledOutOfBounds: Bool = false
    
    @EnvironmentObject
    var appModel: AppGlobals

    // MARK: - init

    init(_ channel: Binding<Channel>, _ guildName: String? = nil, model: StateObject<ChannelViewViewModel>? = nil) {
        self._channel = channel
        self.guildName = guildName ?? "Direct Messages"
        if let model {
            self._viewModel = model
        } else {
            _viewModel = StateObject(wrappedValue: ChannelViewViewModel(channel: channel.wrappedValue))
        }
    }

    @_transparent
    func cell(for binding: Binding<Message>) -> some View {
        let message = binding.wrappedValue
        return MessageCellView(
            message: binding,
            nick: viewModel.nicks[message.author?.id ?? ""],
            replyNick: viewModel.nicks[message.referencedMessage?.author?.id ?? ""],
            pronouns: viewModel.pronouns[message.author?.id ?? ""],
            avatar: viewModel.avatars[message.author?.id ?? ""],
            permissions: $viewModel.permissions,
            role: $viewModel.roles[message.author?.id ?? ""],
            replyRole: $viewModel.roles[message.referencedMessage?.author?.id ?? ""],
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
                Task.detached {
                    await viewModel.loadMoreMessages()
                }
            }
        }
    }
    
    var messagesView: some View {
        ForEach($viewModel.messages, id: \.identifier) { $message in
            let cell = cell(for: $message)
            let showNewMessagesLine = channel.read_state?.last_message_id == message.id && channel.read_state?.last_message_id != channel.last_message_id
            if showNewMessagesLine {
                VStack(alignment: .leading) {
                    HStack {
                        Color.red
                            .frame(height: 1)
                            .opacity(0.4)
                        Text("New messages")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                        Color.red
                            .frame(height: 1)
                            .opacity(0.4)
                    }
                    .padding(.top)
                    cell
                }
            } else if message.inSameDay {
                cell
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Color.secondary
                            .frame(height: 1)
                            .opacity(0.4)
                        Text(message.processedTimestamp?.components(separatedBy: " at ").first ?? "Today")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                        Color.secondary
                            .frame(height: 1)
                            .opacity(0.4)
                    }
                    .padding(.top)
                    cell
                }
            }
        }
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private var channelHeaderView: some View {
        Divider()
        Text("This is the start of the channel")
            .font(.system(size: 15))
            .fontWeight(.semibold)
        Text("Welcome to #\(channelName)!")
            .bold()
            .dynamicTypeSize(.xxxLarge)
            .font(.largeTitle)
    }
    
    
    var body: some View {
        HStack {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    ScrollViewReader { proxy in
                        List {
                            Spacer().frame(height: 15)
                            if metalRenderer {
                                messagesView.drawingGroup()
                            } else {
                                messagesView
                            }
                            if viewModel.noMoreMessages {
                                channelHeaderView
                                    .rotationEffect(.degrees(180))
                                    .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                            } else {
                                MessagePlaceholders()
                            }
                        }
                        .listRowBackground(colorScheme == .dark ? Color.darkListBackground : Color(NSColor.controlBackgroundColor))
                        .rotationEffect(.radians(.pi))
                        .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                        .onReceive(Self.scrollTo, perform: { channelID, id in
                            guard channelID == self.channel.id else { return }
                            if viewModel.messages.map(\.id).contains(id) {
                                withAnimation(.easeInOut(duration: 0.5), {
                                    proxy.scrollTo(id, anchor: .center)
                                })
                            } else {
                                self.scrolledOutOfBounds = true
                                messageFetchQueue.async {
                                    viewModel.loadAroundMessage(id: id)
                                }
                            }
                        })
                    }
                    if self.scrolledOutOfBounds {
                        Button(action: { [weak viewModel] in
                            self.scrolledOutOfBounds = false
                            messageFetchQueue.async {
                                viewModel?.getMessages(channelID: self.channel.id, guildID: self.channel.guild_id ?? "@me", scrollAfter: true)
                            }
                        }) {
                            Image(systemName: "arrowtriangle.down.circle.fill")
                                .font(.system(size: 40))
                                .opacity(0.9)
                        }
                        .buttonStyle(.borderless)
                        .padding(15)
                    }
                }
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
            if showSearch {
                VStack(alignment: .leading) {
                    HStack {
                        TextField("Search", text: self.$searchText)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.large)
                            .onSubmit {
                                self.search()
                            }
                        Spacer()
                        Button(action: {
                            self.showSearch = false
                            self.searchMessages.removeAll()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 5)
                    .padding(.trailing, 5)
                    .padding(.top, 10)
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach($searchMessages, id: \.id) { $message in
                                ZStack(alignment: .topTrailing) {
                                    cell(for: $message)
                                    Button("Jump") {
                                        Storage.globals?.select(channel: Channel(id: message.channelID, type: .normal, guild_id: self.channel.guild_id, position: nil, parent_id: nil))
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                                            ChannelView.scrollTo.send((message.channelID, message.id))
                                        })
                                    }
                                }
                            }
                        }
                    }
                    .onDisappear {
                        self.searchMessages.removeAll()
                    }
                }
                .frame(maxWidth: 400)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                viewModel.memberList = channel.recipients?.map(OPSItems.init) ?? []
            }
            Task.detached {
                await self.viewModel.setPermissions(self.appModel)
            }
        }
        .channelProperties(channelID: self.channel.id, guildID: self.channel.guild_id ?? "@me")
        .navigationTitle(Text("\(viewModel.guildID == "@me" ? "" : "#")\(channelName)".replacingOccurrences(of: "#", with: "")))
        .presentedWindowToolbarStyle(.unifiedCompact)
        .onDrop(of: ["public.file-url"], isTargeted: Binding.constant(false)) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { data, _ in
                if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                    self.fileUploads.append((try? Data(contentsOf: url), url))
                }
            })
            return true
        }
        .onSubmit(of: .search) {
            showSearch = !searchText.isEmpty || self.searchForPinnedMessages
            if showSearch {
                search()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack {
                    Button(action: {
                        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                    }, label: {
                        Image(systemName: "sidebar.leading")
                    })
                    if guildName == "Direct Messages" {
                        Text("@")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.trailing, -2)
                    } else {
                        Image(systemName: "number")
                            .resizable()
                            .frame(width: 13, height: 13)
                            .foregroundColor(.secondary)
                            .padding(.trailing, -2)
                    }
                }
            }
            ToolbarItemGroup {
                if let topic = self.channel.topic {
                    Image(systemName: "info.circle.fill")
                        .popupOnClick(buttonStyle: .bordered) {
                            VStack(alignment: .leading) {
                                Text("#" + self.channelName)
                                    .fontWeight(.semibold)
                                Text(topic)
                                if let threads = self.channel.threads {
                                    Section("Threads", content: {
                                        ForEach(threads, id: \.id) { thread in
                                            Text(thread.name ?? "")
                                        }
                                    })
                                }

                            }
                            .padding(10)
                        }
                }
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
                Toggle(isOn: $showSearch.animation()) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                }
                Toggle(isOn: $memberListShown.animation()) {
                    Image(systemName: "person.2.fill")
                }
            }
        }
    }
    
    func search() {
        var queryParams: [String: String] = [:]
        if !searchText.isEmpty {
            queryParams["content"] = searchText
        }
        
        queryParams["pinned"] = searchForPinnedMessages.description
        
        let url = URL(string: rootURL)!
            .appendingPathComponent("guilds")
            .appendingPathComponent(self.channel.guild_id ?? "@me")
            .appendingPathComponent("messages")
            .appendingPathComponent("search")
            .appendingQueryParameters(queryParams)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
        Request.fetch(SearchResult.self, request: nil, url: url, headers: Headers(
            token: Globals.token,
            type: .GET
        ), decoder: decoder) { result in
            switch result {
            case .success(let messages):
                DispatchQueue.main.async {
                    self.searchMessages = messages.messages.flatMap { $0 }
                }
            case .failure(let error):
                print("Error: \(error)")
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
                    "\(group.id == "offline" ? "OFFLINE" : group.id == "online" ? "OFFLINE" : Storage.roleNames[group.id ?? ""]?.uppercased() ?? "") - \(group.count ?? 0)"
                )
                .fontWeight(.semibold)
                .font(.system(size: 10))
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
                Attachment(pfpURL(ops.member?.user.id ?? "", ops.member?.user.avatar ?? "", discriminator: ops.member?.user.discriminator ?? "", "64"))
                    .equatable()
                    .frame(width: 33, height: 33)
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text(ops.member?.nick ?? ops.member?.user.username ?? "")
                        .fontWeight(.medium)
                        .foregroundColor({ () -> Color in
                            if let role = ops.member?.roles?.first, let color = Storage.roleColors[role]?.0 {
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.borderless)
        .popover(isPresented: self.$popup, content: {
            PopoverProfileView(user: ops.member?.user)
        })
    }
}

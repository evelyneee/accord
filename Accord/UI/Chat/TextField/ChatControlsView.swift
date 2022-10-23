//
//  ChatControlsView.swift
//  ChatControlsView
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI


struct ChatControls: View {
//    enum FocusedElements: Hashable {
//        case mainTextField
//        case none
//    }
//
//    @FocusState private var focusedField: FocusedElements?

    @StateObject var viewModel = ChatControlsViewModel()
    
    var guildID: String
    var channelID: String
    var chatText: String
    var permissions: Permissions
    
    @MainActor @Binding
    var replyingTo: Message?
    
    @MainActor @Binding
    var mentionUser: Bool
    
    @MainActor @Binding
    var fileUploads: [(Data?, URL?)]
    
    @State var nitroless = false
    @State var emotes = false
    @State var dragOver: Bool = false
    
    @MainActor @State
    var fileImport: Bool = false
    
    @MainActor @State
    var typing: Bool = false
    
    @AppStorage("Nitroless")
    var nitrolessEnabled: Bool = false

    var textFieldText: String {
        permissions.contains(.sendMessages) ?
            viewModel.percent ?? chatText :
            "You do not have permission to speak in this channel."
    }

    private func send() {
        messageSendQueue.async { [weak viewModel] in
            guard (viewModel?.textFieldContents != "" || !fileUploads.isEmpty), let contents = viewModel?.textFieldContents else { return }
            if contents.prefix(1) != "/" {
                viewModel?.emptyTextField()
            }
            if !fileUploads.isEmpty {
                viewModel?.send(text: contents, file: self.fileUploads.compactMap(\.1), data: self.fileUploads.compactMap(\.0), channelID: self.channelID)
                DispatchQueue.main.async {
                    self.fileUploads.removeAll()
                }
            } else if let replyingTo = replyingTo {
                viewModel?.send(text: contents, replyingTo: replyingTo, mention: self.mentionUser, guildID: guildID)
                DispatchQueue.main.async {
                    self.replyingTo = nil
                    self.mentionUser = true
                }
            } else if viewModel?.textFieldContents.prefix(1) == "/" {
                Task.detached {
                    try await self.viewModel.executeCommand(guildID: guildID, channelID: channelID)
                }
            } else {
                viewModel?.send(text: contents, guildID: guildID, channelID: channelID)
            }
            // self.focusIfUnfocused()
        }
    }

//    func focusIfUnfocused() {
//        DispatchQueue.main.async {
//            print(self.focusedField)
//            if self.focusedField != .mainTextField {
//                self.focusedField = .mainTextField
//            }
//        }
//    }
    
    var matchedUsersView: some View {
        VStack {
            MatchesView(
                elements: viewModel.matchedUsers.prefix(10),
                id: \.id,
                action: { [weak viewModel] user in
                    if let range = viewModel?.textFieldContents.ranges(of: "@").last {
                        viewModel?.textFieldContents.removeSubrange(range.lowerBound ..< viewModel!.textFieldContents.endIndex)
                    }
                    viewModel?.textFieldContents.append("<@\(user.id)> ")
                },
                label: { user in
                    HStack {
                        Attachment(pfpURL(user.id, user.avatar, discriminator: user.discriminator))
                            .equatable()
                            .clipShape(Circle())
                            .frame(width: 23, height: 23)
                        Text(user.username).foregroundColor(.primary)
                        +
                        Text("#" + user.discriminator)
                        Spacer()
                    }
                }
            )
            if viewModel.matchedUsers.count < 5 {
                if !viewModel.matchedRoles.isEmpty {
                    Divider()
                }
                MatchesView(
                    elements: viewModel.matchedRoles.sorted(by: >).prefix(4),
                    id: \.key,
                    action: { [weak viewModel] key, _ in
                        if let range = viewModel?.textFieldContents.ranges(of: "@").last {
                            viewModel?.textFieldContents.removeSubrange(range.lowerBound ..< viewModel!.textFieldContents.endIndex)
                        }
                        viewModel?.textFieldContents.append("<@\(key)> ")
                    },
                    label: { id, roleName in
                        HStack {
                            Text("@" + roleName)
                                .foregroundColor({
                                    if let color = Storage.roleColors[id.dropFirst().stringLiteral]?.0 {
                                        return Color(int: color)
                                    }
                                    return .primary
                                }())
                            Spacer()
                        }
                    }
                )
            }
        }
    }

    var matchedCommandsView: some View {
        MatchesView(
            elements: viewModel.matchedCommands.prefix(10),
            id: \.id,
            action: { [weak viewModel] command in
                var contents = "/\(command.name)"
                command.options?.forEach { arg in
                    contents.append(" \(arg.name)\(arg.type == 1 ? "" : ":")")
                }
                viewModel?.command = command
                viewModel?.textFieldContents = contents
                viewModel?.matchedCommands.removeAll()
            },
            label: { command in
                HStack {
                    if let command = command, let avatar = command.avatar {
                        Attachment(cdnURL + "/avatars/\(command.application_id)/\(avatar).png?size=48")
                            .equatable()
                            .frame(width: 22, height: 22)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading) {
                        Text(command.name)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(command.description)
                    }
                    Spacer()
                }
            }
        )
    }

    var matchedEmojiView: some View {
        MatchesView(
            elements: viewModel.matchedEmoji.prefix(10),
            id: \.id,
            action: { [weak viewModel] emoji in
                if let range = viewModel?.textFieldContents.ranges(of: ":").last {
                    viewModel?.textFieldContents.removeSubrange(range.lowerBound ..< viewModel!.textFieldContents.endIndex)
                }
                viewModel?.textFieldContents.append("<\((emoji.animated ?? false) ? "a" : ""):\(emoji.name):\(emoji.id)> ")
                viewModel?.matchedEmoji.removeAll()
            },
            label: { emoji in
                HStack {
                    Attachment(cdnURL + "/emojis/\(emoji.id).png?size=80", size: CGSize(width: 48, height: 48))
                        .equatable()
                        .frame(width: 20, height: 20)
                    Text(emoji.name)
                    Spacer()
                }
            }
        )
    }

    var matchedChannelsView: some View {
        MatchesView(
            elements: viewModel.matchedChannels.prefix(10),
            id: \.id,
            action: { [weak viewModel] channel in
                if let range = viewModel?.textFieldContents.ranges(of: "#").last {
                    viewModel?.textFieldContents.removeSubrange(range.lowerBound ..< viewModel!.textFieldContents.endIndex)
                }
                viewModel?.textFieldContents.append("<#\(channel.id)> ")
            },
            label: { channel in
                HStack {
                    Text(channel.name ?? "Unknown Channel")
                    Spacer()
                }
            }
        )
    }
    
    @ViewBuilder
    var textField: some View {
        if #available(macOS 12.0, *) {
            TextField(textFieldText, text: $viewModel.textFieldContents)
                .font(.chatTextFont)
                .onSubmit {
                    typing = false
                    send()
                }
        } else {
            TextField(textFieldText, text: $viewModel.textFieldContents, onCommit: {
                typing = false
                send()
            })
            .font(.chatTextFont)
        }
    }

    var mainTextField: some View {
        textField
            .layoutPriority(1)
            .animation(nil, value: UUID())
            .fixedSize(horizontal: false, vertical: true)
            .onReceive(
                NotificationCenter.default.publisher(for: NSNotification.Name("red.evelyn.accord.PasteEvent"))
                    .debounce(for: RunLoop.SchedulerTimeType.Stride(floatLiteral: 0.05), scheduler: RunLoop.current)
            ) { [weak viewModel] _ in
                let data = NSPasteboard.general.pasteboardItems?.first?.data(forType: .fileURL)
                if let rawData = data,
                   let string = String(data: rawData, encoding: .utf8),
                   let url = URL(string: string),
                   let data = try? Data(contentsOf: url)
                {
                    self.fileUploads.append((data, url))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let textCount = viewModel?.textFieldContents.count,
                           let pathComponentsCount = url.pathComponents.last?.count
                        {
                            if textCount >= pathComponentsCount {
                                viewModel?.textFieldContents.removeLast(pathComponentsCount)
                            }
                        }
                    }
                } else if let image = NSImage(pasteboard: NSPasteboard.general) {
                    self.fileUploads.append((image.png, URL(string: "file:///image0.png")!))
                }
            }
//            .onAppear {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//                    self.focusIfUnfocused()
//                })
//            }
    }

    var fileImportButton: some View {
        Button(action: {
            fileImport.toggle()
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16.5))
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    var nitrolessButton: some View {
        Button(action: {
            nitroless.toggle()
        }) {
            Image(systemName: "rectangle.grid.3x2.fill")
                .font(.system(size: 16.5))
        }
        .buttonStyle(BorderlessButtonStyle())
        .popover(isPresented: $nitroless, content: {
            NitrolessView(chatText: $viewModel.textFieldContents).equatable()
                .frame(width: 300, height: 400)
        })
    }

    var emotesButton: some View {
        Button(action: {
            emotes.toggle()
        }) {
            Image(systemName: "face.smiling.fill")
                .font(.system(size: 16.5))
        }
        .buttonStyle(BorderlessButtonStyle())
        .keyboardShortcut("e", modifiers: [.command])
        .popover(isPresented: $emotes, content: {
            NavigationLazyView(EmotesView(chatText: $viewModel.textFieldContents).equatable())
                .frame(width: 300, height: 400)
        })
    }

    var body: some View {
        HStack { [unowned viewModel] in
            ZStack(alignment: .trailing) {
                VStack {
                    if !(viewModel.matchedUsers.isEmpty) ||
                        !(viewModel.matchedEmoji.isEmpty) ||
                        !(viewModel.matchedChannels.isEmpty) ||
                        !(viewModel.matchedCommands.isEmpty) ||
                        !(viewModel.matchedRoles.isEmpty) &&
                        !viewModel.textFieldContents.isEmpty
                    {
                        VStack {
                            matchedUsersView
                            matchedCommandsView
                            matchedEmojiView
                            matchedChannelsView
                            Divider()
                        }
                        .padding(.bottom, 7)
                    }
                    if !fileUploads.isEmpty {
                        ScrollView(.horizontal, showsIndicators: true) {
                            FileUploadsView(fileUploads: self.$fileUploads)
                        }
                        Divider().padding(.bottom, 7)
                    }
                    HStack {
                        fileImportButton
                        Divider()
                            .frame(height: 20)
                            .padding(.horizontal, 3)
                        mainTextField
                        if nitrolessEnabled {
                            nitrolessButton
                        }
                        emotesButton
                    }
                    .disabled(!self.permissions.contains(.sendMessages))
                    .onReceive(viewModel.$textFieldContents) { _ in
                        if !typing, viewModel.textFieldContents != "" {
                            messageSendQueue.async {
                                viewModel.type(channelID: self.channelID, guildID: self.guildID)
                            }
                            typing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                typing = false
                            }
                        }
                        // viewModel?.markdown()
                        Task.detached {
                            await viewModel.checkText(guildID: guildID, channelID: channelID)
                        }
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                .fileImporter(isPresented: $fileImport, allowedContentTypes: [.data]) { result in
                    self.fileUploads.append((try? Data(contentsOf: try! result.get()), try? result.get()))
                }
                .onExitCommand { self.replyingTo = nil }
            }
        }
    }
}

extension Data {
    mutating func append(string: String, encoding: String.Encoding) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict: [Element: Bool] = .init()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = removingDuplicates()
    }
}

/*
 if Globals.plugins != [] {
     ForEach(Globals.plugins.enumerated().reversed().reversed(), id: \.offset) { offset, plugin in
         if pluginPoppedUp.indices.contains(offset) {
             Button(action: {
                 pluginPoppedUp[offset].toggle()
             }) {
                 Image(systemName: plugin.symbol)
             }
             .buttonStyle(BorderlessButtonStyle())
             .popover(isPresented: $pluginPoppedUp[offset], content: {
                 NSViewWrapper(plugin.body ?? NSView())
                     .frame(width: 200, height: 200)
             })
         }
     }
 }
 */

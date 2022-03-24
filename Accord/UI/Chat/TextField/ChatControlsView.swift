//
//  ChatControlsView.swift
//  ChatControlsView
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

struct ChatControls: View {
    
    @available(macOS 12.0, *)
    enum FocusedElements: Hashable {
      case mainTextField
    }
    
    @available(macOS 12.0, *)
    @FocusState private var focusedField: FocusedElements?
    
    @State var chatTextFieldContents: String = ""
    @State var pfps: [String: NSImage] = [:]
    @Binding var guildID: String
    @Binding var channelID: String
    @Binding var chatText: String
    @Binding var replyingTo: Message?
    @State var nitroless = false
    @State var emotes = false
    @State var fileImport: Bool = false
    @Binding var fileUpload: Data?
    @Binding var fileUploadURL: URL?
    @State var dragOver: Bool = false
    @State var pluginPoppedUp: [Bool] = Array(repeating: false, count: AccordCoreVars.plugins.count)
    @StateObject var viewModel = ChatControlsViewModel()
    @State var typing: Bool = false
    weak var textField: NSTextField?
    @AppStorage("Nitroless") var nitrolessEnabled: Bool = false

    private func send() {
        messageSendQueue.async { [weak viewModel] in
            guard viewModel?.textFieldContents != "", let contents = viewModel?.textFieldContents else { return }
            if contents.prefix(1) != "/" {
                viewModel?.emptyTextField()
            }
            if let fileUpload = fileUpload, let fileUploadURL = fileUploadURL {
                viewModel?.send(text: contents, file: fileUploadURL, data: fileUpload, channelID: self.channelID)
                DispatchQueue.main.async {
                    self.fileUpload = nil
                    self.fileUploadURL = nil
                }
            } else if let replyingTo = replyingTo {
                self.replyingTo = nil
                viewModel?.send(text: contents, replyingTo: replyingTo, mention: true, guildID: guildID)
            } else if viewModel?.textFieldContents.prefix(1) == "/" {
                try? viewModel?.executeCommand(guildID: guildID, channelID: channelID)
            } else {
                viewModel?.send(text: contents, guildID: guildID, channelID: channelID)
            }
            if #available(macOS 12.0, *) {
                DispatchQueue.main.async {
                    self.focusedField = .mainTextField
                }
            }
        }
    }
    
    var matchedUsersView: some View {
        ForEach(viewModel.matchedUsers.sorted(by: >).prefix(10), id: \.key) { id, username in
            Button(action: { [weak viewModel] in
                if let range = viewModel?.textFieldContents.range(of: "@") {
                    viewModel?.textFieldContents.removeSubrange(range.lowerBound ..< viewModel!.textFieldContents.endIndex)
                }
                viewModel?.textFieldContents.append("<@!\(id)>")
            }, label: {
                HStack {
                    Text(username)
                    Spacer()
                }
            })
            .buttonStyle(.borderless)
            .padding(3)
        }
    }
    
    var matchedCommandsView: some View {
        ForEach(viewModel.matchedCommands.prefix(10), id: \.id) { command in
            Button.init(action: { [weak command, weak viewModel] in
                guard let command = command else { return }
                var contents = "/\(command.name)"
                command.options?.forEach { arg in
                    contents.append(" \(arg.name)\(arg.type == 1 ? "" : ":")")
                }
                viewModel?.command = command
                viewModel?.textFieldContents = contents
                viewModel?.matchedCommands.removeAll()
            }, catch: { error in
                print("Interaction Failed", error as Any)
            }, label: { [weak command] in
                HStack {
                    if let command = command, let avatar = command.avatar {
                        Attachment(cdnURL + "/avatars/\(command.application_id)/\(avatar).png?size=48")
                            .equatable()
                            .frame(width: 22, height: 22)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading) {
                        Text(command?.name ?? "Unknown Command")
                            .fontWeight(.semibold)
                        Text(command?.description ?? "Some slash command")
                    }
                    Spacer()
                }
            })
            .buttonStyle(.borderless)
            .padding(3)
        }
    }
    
    var matchedEmojiView: some View {
        ForEach(viewModel.matchedEmoji.prefix(10), id: \.id) { emoji in
            HStack {
                Button(action: { [weak viewModel] in
                    if let range = viewModel?.textFieldContents.range(of: ":") {
                        viewModel?.textFieldContents.removeSubrange(range.lowerBound ..< viewModel!.textFieldContents.endIndex)
                    }
                    viewModel?.textFieldContents.append("<\((emoji.animated ?? false) ? "a" : ""):\(emoji.name):\(emoji.id)>")
                    viewModel?.matchedEmoji.removeAll()
                }, label: {
                    HStack {
                        Attachment(cdnURL + "/emojis/\(emoji.id).png?size=80", size: CGSize(width: 48, height: 48))
                            .equatable()
                            .frame(width: 20, height: 20)
                        Text(emoji.name)
                        Spacer()
                    }
                })
                .buttonStyle(.borderless)
                .padding(3)
                Button("Send link") { [weak viewModel] in
                    if let range = viewModel?.textFieldContents.range(of: ":") {
                        viewModel?.textFieldContents.removeSubrange(range.lowerBound ..< viewModel!.textFieldContents.endIndex)
                    }
                    viewModel?.textFieldContents.append(cdnURL + "/emojis/\(emoji.id).png?size=48")
                    viewModel?.matchedEmoji.removeAll()
                }
                .buttonStyle(.borderless)
                .padding(3)
            }
        }
    }
    
    var matchedChannelsView: some View {
        ForEach(viewModel.matchedChannels.prefix(10), id: \.id) { channel in
            Button(action: { [weak viewModel] in
                if let range = viewModel?.textFieldContents.range(of: "#") {
                    viewModel?.textFieldContents.removeSubrange(range.lowerBound ..< viewModel!.textFieldContents.endIndex)
                }
                viewModel?.textFieldContents.append("<#\(channel.id)>")
            }) {
                HStack {
                    Text(channel.name ?? "Unknown Channel")
                    Spacer()
                }
            }
            .buttonStyle(.borderless)
            .padding(3)
        }
    }
    
    @available(macOS 12.0, *)
    var montereyTextField: some View {
        TextField(viewModel.percent ?? chatText, text: $viewModel.textFieldContents)
            .focused($focusedField, equals: .mainTextField)
            .onSubmit {
                typing = false
                send()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NSMenuWillSendActionNotification"))) { [weak viewModel] pub in
                if String(describing: pub.userInfo).contains("Command-V") && self.focusedField == .mainTextField {
                    let data = NSPasteboard.general.pasteboardItems?.first?.data(forType: .fileURL)
                    if let rawData = data,
                        let string = String(data: rawData, encoding: .utf8),
                        let url = URL(string: string),
                        let data = try? Data(contentsOf: url) {
                            self.fileUpload = data
                            self.fileUploadURL = url
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                if (viewModel?.textFieldContents.count ?? -1) >= (url.pathComponents.last?.count ?? 0) {
                                    viewModel?.textFieldContents.removeLast(url.pathComponents.last?.count ?? 0)
                                }
                            })
                    }
                }
            }
            .onAppear {
                self.focusedField = .mainTextField
            }
    }
    
    var bigSurTextField: some View {
        TextField(viewModel.percent ?? chatText, text: $viewModel.textFieldContents, onEditingChanged: { _ in }) {
            typing = false
            send()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NSMenuWillSendActionNotification"))) { [weak viewModel] pub in
            if String(describing: pub.userInfo).contains("Command-V") {
                let data = NSPasteboard.general.pasteboardItems?.first?.data(forType: .fileURL)
                if let rawData = data,
                    let string = String(data: rawData, encoding: .utf8),
                    let url = URL(string: string),
                    let data = try? Data(contentsOf: url) {
                        self.fileUpload = data
                        self.fileUploadURL = url
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            if (viewModel?.textFieldContents.count ?? -1) >= (url.pathComponents.last?.count ?? 0) {
                                viewModel?.textFieldContents.removeLast(url.pathComponents.last?.count ?? 0)
                            }
                        })
                }
            }
        }
    }
    
    var fileImportButton: some View {
        Button(action: {
            fileImport.toggle()
        }) {
            Image(systemName: "plus.circle.fill")
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    var nitrolessButton: some View {
        Button(action: {
            nitroless.toggle()
        }) {
            Image(systemName: "rectangle.grid.3x2.fill")
        }
        .buttonStyle(BorderlessButtonStyle())
        .popover(isPresented: $nitroless, content: {
            NavigationLazyView(NitrolessView(chatText: $viewModel.textFieldContents).equatable())
                .frame(width: 300, height: 400)
        })
    }
    
    var emotesButton: some View {
        Button(action: {
            emotes.toggle()
        }) {
            Image(systemName: "face.smiling.fill")
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
                    if !(viewModel.matchedUsers.isEmpty) || !(viewModel.matchedEmoji.isEmpty) || !(viewModel.matchedChannels.isEmpty) || !(viewModel.matchedCommands.isEmpty) {
                        VStack {
                            matchedUsersView
                            matchedCommandsView
                            matchedEmojiView
                            matchedChannelsView
                            Divider()
                        }
                        .padding(.bottom, 7)
                    }
                    HStack {
                        if #available(macOS 12.0, *) {
                            montereyTextField
                        } else {
                            bigSurTextField
                        }
                        fileImportButton
                        if nitrolessEnabled {
                            nitrolessButton
                        }
                        emotesButton
                        HStack {
                            if fileUpload != nil {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(Color.secondary)
                            }
                        }
                    }
                    .onReceive(viewModel.$textFieldContents) { [weak viewModel] _ in
                        if !typing, viewModel?.textFieldContents != "" {
                            messageSendQueue.async {
                                viewModel?.type(channelID: self.channelID, guildID: self.guildID)
                            }
                            typing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                typing = false
                            }
                        }
                        viewModel?.markdown()
                        textQueue.async {
                            viewModel?.checkText(guildID: guildID)
                        }
                    }
                }
                .onAppear {
                    viewModel.findView()
                }
                .textFieldStyle(PlainTextFieldStyle())
                .fileImporter(isPresented: $fileImport, allowedContentTypes: [.data]) { result in
                    fileUpload = try! Data(contentsOf: try! result.get())
                    fileUploadURL = try! result.get()
                }
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
 if AccordCoreVars.plugins != [] {
     ForEach(AccordCoreVars.plugins.enumerated().reversed().reversed(), id: \.offset) { offset, plugin in
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

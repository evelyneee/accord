//
//  ChatControlsView.swift
//  ChatControlsView
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

struct ChatControls: View {
    @State var chatTextFieldContents: String = ""
    @State var pfps: [String : NSImage] = [:]
    @Binding var guildID: String
    @Binding var channelID: String
    @Binding var chatText: String
    @Binding var replyingTo: Message?
    @State var nitroless = false
    @State var emotes = false
    @State var fileImport: Bool = false
    @State var fileUpload: Data? = nil
    @State var fileUploadURL: URL? = nil
    @State var dragOver: Bool = false
    @State var pluginPoppedUp: [Bool] = []
    @Binding var users: [User]
    @StateObject var viewModel = ChatControlsViewModel()
    @State var typing: Bool = false
    
    fileprivate func uploadFile(temp: String, url: URL? = nil) {
        var request = URLRequest(url: URL(string: "\(rootURL)/channels/\(channelID)/messages")!)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let params: [String : String]? = [
            "content" :String(temp)
        ]
        request.addValue(AccordCoreVars.shared.token, forHTTPHeaderField: "Authorization")
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        for (key, _) in params! {
            body.append(string: boundaryPrefix, encoding: .utf8)
            body.append(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n", encoding: .utf8)
            body.append(string: "\(params!["content"]!)\r\n", encoding: .utf8)
        }
        body.append(string: boundaryPrefix, encoding: .utf8)
        let mimeType = fileUploadURL?.mimeType()
        body.append(string: "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileUploadURL?.pathComponents.last ?? "file.txt")\"\r\n", encoding: .utf8)
        body.append(string: "Content-Type: \(mimeType ?? "application/octet-stream") \r\n\r\n", encoding: .utf8)
        body.append(fileUpload!)
        body.append(string: "\r\n", encoding: .utf8)
        body.append(string: "--".appending(boundary.appending("--")), encoding: .utf8)
        request.httpBody = body
        URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
        }).resume()
    }
    var body: some View {
        HStack {
            ZStack(alignment: .trailing) {
                VStack {
                    if !(viewModel.matchedUsers.isEmpty) || !(viewModel.matchedEmoji.isEmpty) {
                        ForEach(viewModel.matchedUsers.prefix(10), id: \.id) { user in
                            Button(action: { [weak viewModel, weak user] in
                                if let range = viewModel?.textFieldContents.range(of: "@") {
                                    viewModel?.textFieldContents.removeSubrange(range.lowerBound..<viewModel!.textFieldContents.endIndex)
                                }
                                viewModel?.textFieldContents.append("<@!\(user?.id ?? "")>")
                            }, label: { [weak user] in
                                HStack {
                                    Attachment(pfpURL(user?.id, user?.avatar).appending("?size=24"), size: CGSize(width: 48, height: 48))
                                        .clipShape(Circle())
                                        .frame(width: 20, height: 20)
                                    Text(user?.username ?? "Unknown User")
                                    Spacer()
                                }
                            })
                            .buttonStyle(.borderless)
                            .padding(5)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(10)
                        }
                        ForEach(viewModel.matchedEmoji.prefix(10), id: \.id) { emoji in
                            Button(action: { [weak viewModel, weak emoji] in
                                if let range = viewModel?.textFieldContents.range(of: ":") {
                                    viewModel?.textFieldContents.removeSubrange(range.lowerBound..<viewModel!.textFieldContents.endIndex)
                                }
                                viewModel?.textFieldContents.append("<\((emoji?.animated ?? false) ? "a" : ""):\(emoji?.name ?? ""):\(emoji?.id ?? "")>")
                            }, label: { [weak emoji] in
                                HStack {
                                    Attachment("https://cdn.discordapp.com/emojis/\(emoji?.id ?? "").png?size=80", size: CGSize(width: 48, height: 48))
                                        .frame(width: 20, height: 20)
                                    Text(emoji?.name ?? "Unknown Emote")
                                    Spacer()
                                }
                            })
                            .buttonStyle(.borderless)
                            .padding(5)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(10)
                        }
                    }
                    HStack {
                        TextField(chatText, text: $viewModel.textFieldContents, onEditingChanged: { state in
                        }, onCommit: {
                            messageSendQueue.async { [weak viewModel] in
                                if viewModel?.textFieldContents == "/shrug" {
                                    viewModel?.textFieldContents = #"¯\_(ツ)_/¯"#
                                }
                                if fileUpload != nil {
                                    uploadFile(temp: viewModel?.textFieldContents ?? "")
                                    fileUpload = nil
                                    fileUploadURL = nil
                                } else {
                                    if replyingTo != nil {
                                        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages"), headers: Headers(
                                            userAgent: discordUserAgent,
                                            token: AccordCoreVars.shared.token,
                                            bodyObject: ["content":"\(String(viewModel?.textFieldContents ?? ""))", "allowed_mentions":["parse":["users","roles","everyone"], "replied_user":true], "message_reference":["channel_id":channelID, "message_id":replyingTo?.id ?? ""]],
                                            type: .POST,
                                            discordHeaders: true,
                                            referer: "https://discord.com/channels/\(guildID)/\(channelID)",
                                            empty: true,
                                            json: true
                                        ))
                                        replyingTo = nil
                                    } else {
                                        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages"), headers: Headers(
                                            userAgent: discordUserAgent,
                                            token: AccordCoreVars.shared.token,
                                            bodyObject: ["content":"\(String(viewModel?.textFieldContents ?? ""))"],
                                            type: .POST,
                                            discordHeaders: true,
                                            empty: true,
                                            json: true
                                        ))
                                    }
                                }
                                DispatchQueue.main.async {
                                    viewModel?.textFieldContents = ""
                                }
                            }
                        })
                        Button(action: {
                            fileImport.toggle()
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(BorderlessButtonStyle())
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
                        Button(action: {
                            emotes.toggle()
                        }) {
                            Text("🥺")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .keyboardShortcut("e", modifiers: [.command])
                        .popover(isPresented: $emotes, content: {
                            NavigationLazyView(EmotesView(chatText: $viewModel.textFieldContents).equatable())
                                .frame(width: 300, height: 400)
                        })
                    }
                    .padding(15)
                    .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                    .cornerRadius(15)
                    .onAppear(perform: {
                        viewModel.cachedUsers = self.users
                    })
                    .onChange(of: users, perform: { value in
                        self.viewModel.cachedUsers = value
                    })
                    .onChange(of: viewModel.textFieldContents) { [weak viewModel] new in
                        if viewModel?.textFieldContents != new && !(typing) {
                            messageSendQueue.async {
                                Request.ping(url: URL(string: "https://discord.com/api/v9/channels/\(channelID)/typing"), headers: Headers(
                                    userAgent: discordUserAgent,
                                    token: AccordCoreVars.shared.token,
                                    type: .POST,
                                    discordHeaders: true,
                                    referer: "https://discord.com/channels/\(guildID)/\(channelID)"
                                ))
                            }
                            typing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                                typing = false
                            })
                        }
                    }
                    .onReceive(viewModel.$textFieldContents, perform: { new in
                        textQueue.async {
                            viewModel.checkText()
                        }
                    })
                }
                .onAppear(perform: {
                    for _ in AccordCoreVars.shared.plugins {
                        pluginPoppedUp.append(false)
                    }
                })
                .textFieldStyle(PlainTextFieldStyle())
                .fileImporter(isPresented: $fileImport, allowedContentTypes: [.data]) { result in
                    fileUpload = try! Data(contentsOf: try! result.get())
                    fileUploadURL = try! result.get()
                }
                .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                    providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                        if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                            fileUpload = try! Data(contentsOf: url)
                            fileUploadURL = url
                        }
                    })
                    return true
                }
                HStack {
                    if fileUpload != nil {
                        Image(systemName: "doc.fill")
                            .foregroundColor(Color.secondary)
                    }
                    /*
                    if AccordCoreVars.shared.plugins != [] {
                        ForEach(AccordCoreVars.shared.plugins.enumerated().reversed().reversed(), id: \.offset) { offset, plugin in
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

final class ChatControlsViewModel: ObservableObject {
    
    @Published var matchedUsers = [User]()
    @Published var matchedEmoji = [DiscordEmote]()
    @Published var textFieldContents: String = ""
    @Published var cachedUsers = [User]()
    
    func checkText() {
        let mentions = textFieldContents.matches(for: #"(?<=@)(?:(?!\ ).)*"#)
        let channels = textFieldContents.matches(for: #"(?<=\/)(?:(?!\ ).)*"#)
        let slashes = textFieldContents.matches(for: #"(?<=\/)(?:(?!\ ).)*"#)
        let emoji = textFieldContents.matches(for: #"(?<=:).*"#)
        if !(mentions.isEmpty) {
            let search = mentions[0]
            let matched = cachedUsers.filter { $0.username.lowercased().contains(search.lowercased()) }
            DispatchQueue.main.async { [weak self] in
                self?.matchedUsers = matched.removingDuplicates()
            }
        } else if !(channels.isEmpty) {
            // TODO: Channel completion implementation here
        } else if !(slashes.isEmpty) {
            // TODO: Slash command implementation here
        } else if !(emoji.isEmpty) {
            let key = emoji[0]
            let matched: [DiscordEmote] = Array(Emotes.emotes.values.joined()).filter { $0.name.lowercased().contains(key) }
            DispatchQueue.main.async { [weak self] in
                self?.matchedEmoji = matched
            }
        }
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}

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
    
    // MARK: Equatable protocol
    static func == (lhs: GuildView, rhs: GuildView) -> Bool {
        return lhs.data == rhs.data
    }
    
    @Binding var guildID: String
    @Binding var channelID: String
    @Binding var channelName: String
    @State var chatTextFieldContents: String = ""
    @State var data: [Message] = []
    @State var sending: Bool = false
    @State var typing: [String] = []
    @State var collapsed: [Int] = []
    @State var pfpArray: [String:NSImage] = [:]
    @State var nicks: [String:String] = [:]
    @State var roles: [String:[String]] = [:]
    @State var members: [String:String] = [:]
    @State var replyingTo: Message? = nil
    @State var poppedUpUserProfile: Bool = false
    @State var userPoppedUp: User? = nil
    @State var error: String? = nil
//    actual view begins here

    var body: some View {
//      chat view
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottom) {
                Spacer()
                List {
                    LazyVStack {
                        Spacer().frame(height: 93)
                        // MARK: Sending animation
                        if (sending) && chatTextFieldContents != "", let temp = chatTextFieldContents {
                            HStack(alignment: .top) {
                                Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                                    .scaledToFit()
                                    .frame(width: 33, height: 33)
                                    .padding(.horizontal, 5)
                                    .clipShape(Circle())
                                VStack(alignment: .leading) {
                                    Text(username)
                                        .fontWeight(.semibold)
                                    Text(temp)
                                }
                                Spacer()
                            }
                            .rotationEffect(.radians(.pi))
                            .scaleEffect(x: -1, y: 1, anchor: .center)
                            .opacity(0.75)
                        }
                        // MARK: Message loop
                        ForEach(Array(data), id: \.id) { message in
                            /// get index of message (fixes the index out of range)
                            if let offset = data.firstIndex(of: message) {
                                if data.contains(data[offset]) {
                                    LazyVStack(alignment: .leading) {
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
                                        HStack(alignment: .top) {
                                            VStack {
                                                if offset != data.count - 1 && (message.author?.username ?? "" != (data[Int(offset + 1)].author?.username ?? "")) {
                                                    Button(action: { [weak message] in
                                                        poppedUpUserProfile.toggle()
                                                        userPoppedUp = message!.author!
                                                    }) {
                                                        Image(nsImage: NSImage(data: message.author?.pfp ?? Data()) ?? NSImage()).resizable()
                                                            .scaledToFit()
                                                            .frame(width: (pfpShown ? 33 : 15), height: (pfpShown ? 33 : 15))
                                                            .padding(.horizontal, 5)
                                                            .clipShape(Circle())
                                                    }
                                                    .buttonStyle(BorderlessButtonStyle())
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
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("This is the beginning of #\(channelName)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                            }
                            .padding(.vertical)
                            .rotationEffect(.radians(.pi))
                            .scaleEffect(x: -1, y: 1, anchor: .center)
                        }
                    }
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                VStack(alignment: .leading) {
                    HStack {
                        if typing.count == 1 && !(typing.isEmpty) {
                            Text(channelID != "@me" ? "\(typing.map{ "\($0)" }.joined(separator: ", ")) is typing..." : "\(channelName) is typing...")
                                .padding(4)
                                .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                                .cornerRadius(5)
                        } else if !(typing.isEmpty) {
                            Text("\(typing.map{ "\($0)" }.joined(separator: ", ")) are typing...")
                                .lineLimit(0)
                                .padding(4)
                                .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                                .cornerRadius(5)
                        }
                        if let replied = replyingTo {
                            Text("replying to \(replied.author?.username ?? "")")
                                .padding(4)
                                .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                                .cornerRadius(5)
                        }
                    }
                    if #available(macOS 12.0, *) {
                        ChatControls(chatTextFieldContents: $chatTextFieldContents, channelID: $channelID, chatText: Binding.constant("Message #\(channelName)"), sending: $sending, replyingTo: $replyingTo)
                            .padding(15)
                            .background(Material.regular) // blurred background
                            .cornerRadius(15)
                    } else {
                        ChatControls(chatTextFieldContents: $chatTextFieldContents, channelID: $channelID, chatText: Binding.constant("Message #\(channelName)"), sending: $sending, replyingTo: $replyingTo)
                            .padding(15)
                            .background(VisualEffectView(material: NSVisualEffectView.Material.sheet, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                            .cornerRadius(15)
                    }
                }
                .padding()
            }
            .onAppear {
                if AccordCoreVars.shared.token != "" {
                    concurrentQueue.async {
                        NetworkHandling.shared?.requestData(url: "\(rootURL)/channels/\(channelID)/messages?limit=100", token: AccordCoreVars.shared.token, json: true, type: .GET, bodyObject: [:]) { success, rawData in
                            if success == true {
                                do {
                                    data = try JSONDecoder().decode([Message].self, from: rawData!)
                                    secondLoadQueue.async {
                                        if guildID != "@me" {
                                            let allUserIDs = data.map { $0.author?.id ?? "" }
                                            WebSocketHandler.shared.getMembers(ids: allUserIDs, guild: guildID) { success, users in
                                                if success {
                                                    for person in users {
                                                        nicks[(person?.user.id ?? "")] = person?.nick ?? ""
                                                    }
                                                }
                                            }

                                        }
                                        let authorArray = Array(NSOrderedSet(array: data.compactMap { $0.author! }))
                                        for user in authorArray as! [User] {
                                            if let url = URL(string: "https://cdn.discordapp.com/avatars/\(user.id)/\(user.avatar ?? "").png?size=80") {
                                                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                                                if let data = cache.cachedResponse(for: request)?.data {
                                                    user.pfp = data
                                                } else {
                                                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                                        if let data = data, let response = response {
                                                        let cachedData = CachedURLResponse(response: response, data: data)
                                                            cache.storeCachedResponse(cachedData, for: request)
                                                            user.pfp = data
                                                        }
                                                    }).resume()
                                                }
                                            }
                                        }
                                        let replyArray = Array(NSOrderedSet(array: data.compactMap { $0.referenced_message?.author }))
                                        for user in replyArray as! [User] {
                                            if let url = URL(string: "https://cdn.discordapp.com/avatars/\(user.id)/\(user.avatar ?? "").png?size=80") {
                                                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                                                if let data = cache.cachedResponse(for: request)?.data {
                                                    user.pfp = data
                                                } else {
                                                    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                                        if let data = data, let response = response {
                                                        let cachedData = CachedURLResponse(response: response, data: data)
                                                            cache.storeCachedResponse(cachedData, for: request)
                                                            user.pfp = data
                                                        }
                                                    }).resume()
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                }
                            }
                        }
                    }
                }
            }
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


        /* Run everything into a separate queue so it doesn't clog the main thread */
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("update"))) { notif in
            switch ((Array((notif.userInfo as! [String:Any]).keys))[0]) {
            case "NewMessageIn\(channelID)":
                webSocketQueue.async {
                    sending = false
                    guard let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: notif.userInfo!["NewMessageIn\(channelID)"] as! Data) else { return }
                    guard let message = gatewayMessage.d else { return }
                    if let url = URL(string: "https://cdn.discordapp.com/avatars/\(message.author?.id ?? "")/\(message.author?.avatar ?? "").png?size=80") {
                        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                        if let data = cache.cachedResponse(for: request)?.data {
                            message.author?.pfp = data
                        } else {
                            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                if let data = data, let response = response {
                                let cachedData = CachedURLResponse(response: response, data: data)
                                    cache.storeCachedResponse(cachedData, for: request)
                                    message.author?.pfp = data
                                }
                            }).resume()
                        }
                    }
                    if message.referenced_message != nil {
                        if let url = URL(string: "https://cdn.discordapp.com/avatars/\(message.referenced_message?.author?.id ?? "")/\(message.referenced_message?.author?.avatar ?? "").png?size=80") {
                            let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                            if let data = cache.cachedResponse(for: request)?.data {
                                message.referenced_message?.author?.pfp = data
                            } else {
                                URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                                    if let data = data, let response = response {
                                    let cachedData = CachedURLResponse(response: response, data: data)
                                        cache.storeCachedResponse(cachedData, for: request)
                                        message.referenced_message?.author?.pfp = data
                                    }
                                }).resume()
                            }
                        }
                    }
                    data.insert(message, at: 0)
                }
                break
            case "MemberChunk":
                webSocketQueue.async {
                    guard let chunk = try? JSONDecoder().decode(GuildMemberChunkResponse.self, from: notif.userInfo!["MemberChunk"] as! Data) else { return }
                    guard let users = chunk.d?.members else { return }
                    ChannelMembers.shared.channelMembers[channelID] = Dictionary(uniqueKeysWithValues: zip(users.compactMap { $0!.user.id }, users.compactMap { $0?.nick ?? $0!.user.username }))
                    for person in users {
                        let nickname = person?.nick ?? person?.user.username ?? ""
                        nicks[(person?.user.id ?? "")] = nickname
                        var rolesTemp: [String] = []
                        for _ in 0..<100 {
                            rolesTemp.append("empty")
                        }
                        for role in (person?.roles ?? []) {
                            rolesTemp[roleColors[role]?.1 ?? 0] = role
                        }
                        rolesTemp = rolesTemp.compactMap { role -> String? in
                            if role == "empty" {
                                return nil
                            } else {
                                return role
                            }
                        }
                        rolesTemp = rolesTemp.reversed()
                        roles[(person?.user.id ?? "")] = rolesTemp
                    }
                }
                break
            case "EditedMessageIn\(channelID)":
                print("[Accord] \(channelName) was being updated")
                webSocketQueue.async {
                    let currentUIDDict = data.map { $0.id }
                    guard let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: notif.userInfo!["EditedMessageIn\(channelID)"] as! Data) else { return }
                    guard let message = gatewayMessage.d else { return }
                    data[(currentUIDDict).firstIndex(of: message.id) ?? 0] = message
                }
                break
            case "DeletedMessageIn\(channelID)":
                print("[Accord] \(channelName) is being updated")
                let currentUIDDict = data.map { $0.id }
                guard let gatewayMessage = try? JSONDecoder().decode(GatewayDeletedMessage.self, from: notif.userInfo!["DeletedMessageIn\(channelID)"] as! Data) else { return }
                guard let message = gatewayMessage.d else { return }
                guard let index = (currentUIDDict).firstIndex(of: message.id) else { return }
                data.remove(at: index)
                break
            case "TypingStartIn\(channelID)":
                print("[Accord] typing 1")
                webSocketQueue.async {
                    guard let packet = (notif.userInfo ?? [:])["TypingStartIn\(channelID)"] else { return }
                    print("[Accord] typing 2")
                    if !(typing.contains((notif.userInfo ?? [:])["user_id"] as? String ?? "")) {
                        print("[Accord] typing 3")
                        let memberData = try! JSONSerialization.data(withJSONObject: packet, options: [])
                        let memberDecodable = try! JSONDecoder().decode(TypingEvent.self, from: memberData)
                        guard let nick = memberDecodable.member?.nick else {
                            print("[Accord] typing 4", memberDecodable.member?.user.username ?? "")
                            typing.append(memberDecodable.member?.user.username ?? "")
                            DispatchQueue.global().asyncAfter(deadline: .now() + 7, execute: {
                                typing.remove(at: typing.firstIndex(of: memberDecodable.member?.user.username ?? "") ?? 0)
                            })
                            return
                        }
                        print("[Accord] typing 4", nick)
                        typing.append(nick)
                        DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
                            typing.remove(at: typing.firstIndex(of: (nick)) ?? 0)
                        })
                    }
                }
                break
            case "WSError":
                error = (notif.userInfo as! [String:Any])["WSError"] as? String ?? ""
            default:
                break
            }
        }
    }
}


struct ChatControls: View {
    @Binding var chatTextFieldContents: String 
    @State var textFieldContents: String = ""
    @State var pfps: [String : NSImage] = [:]
    @Binding var channelID: String
    @Binding var chatText: String
    @Binding var sending: Bool
    @Binding var replyingTo: Message?
    @State var nitroless = false
    @State var emotes = false
    @State var temporaryText = ""
    @State var fileImport: Bool = false
    @State var fileUpload: Data? = nil
    func refresh() {
        DispatchQueue.main.async {
            sending = false
            chatTextFieldContents = textFieldContents
        }
    }
    var body: some View {
        HStack {
            ZStack(alignment: .trailing) {
                TextField(chatText, text: $textFieldContents, onEditingChanged: { state in
                    print("balls")
                    if state == true {
                        NetworkHandling.shared?.emptyRequest(url: "https://discord.com/api/v9/channels/\(channelID)/typing", token: AccordCoreVars.shared.token, json: false, type: .POST, bodyObject: [:])
                    }
                }, onCommit: {
                    chatTextFieldContents = textFieldContents
                    var temp = textFieldContents
                    textFieldContents = ""
                    sending = true
                    DispatchQueue.main.async {
                        if temp == "/shrug" {
                            temp = #"¯\_(ツ)_/¯"#
                        }
                        if fileUpload != nil {
                            NetworkHandling.shared?.emptyRequest(url: "\(rootURL)/channels/\(channelID)/messages", token: AccordCoreVars.shared.token, json: false, type: .POST, bodyObject: ["payload_json":["content":"\(String(temp))"], "file":fileUpload as Any])
                        } else {
                            if replyingTo != nil {
                                NetworkHandling.shared?.emptyRequest(url: "\(rootURL)/channels/\(channelID)/messages", token: AccordCoreVars.shared.token, json: true, type: .POST, bodyObject: ["content":"\(String(temp))", "allowed_mentions":["parse":["users","roles","everyone"], "replied_user":true], "message_reference":["channel_id":channelID, "message_id":replyingTo?.id ?? ""]])
                                replyingTo = nil
                            } else {
                                NetworkHandling.shared?.emptyRequest(url: "\(rootURL)/channels/\(channelID)/messages", token: AccordCoreVars.shared.token, json: false, type: .POST, bodyObject: ["content":"\(String(temp))"])
                            }

                        }

                    }
                })
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color.white)
                    .fileImporter(isPresented: $fileImport, allowedContentTypes: [.data]) { result in
                        fileUpload = try! Data(contentsOf: try! result.get())
                    }
                HStack {
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
                        NitrolessView(chatText: $temporaryText).equatable()
                            .frame(width: 300, height: 400)
                    })
                    Button(action: {
                        emotes.toggle()
                    }) {
                        Text("🥺")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .popover(isPresented: $emotes, content: {
                        EmotesView(chatText: $temporaryText).equatable()
                            .frame(width: 300, height: 400)
                    })
                    .onChange(of: temporaryText) { newValue in
                        textFieldContents = newValue
                    }
                    .onChange(of: textFieldContents) { newValue in
                        temporaryText = newValue
                    }
                }
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

struct NativeButton: NSViewRepresentable {

    var title: String? = ""
    var image: NSImage? = nil
    let action: () -> Void

    init(
        _ title: String? = "",
        image: NSImage? = nil,
        keyEquivalent: KeyEquivalent? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.image = image ?? NSImage()
        self.action = action
    }

    func makeNSView(context: NSViewRepresentableContext<Self>) -> NSButton {
        if let buttonImage = image {
            let button = NSButton(
                image: buttonImage, target: nil, action: nil
            )
            button.isBordered = false
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setContentHuggingPriority(.defaultHigh, for: .vertical)
            button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return button
        } else {
            let button = NSButton(title: "", target: nil, action: nil)
            button.title = self.title ?? ""
            button.isBordered = false
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setContentHuggingPriority(.defaultHigh, for: .vertical)
            button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return button
        }

    }

    func updateNSView(_ nsView: NSButton, context: NSViewRepresentableContext<Self>) {
        if title == nil {
            nsView.title = title ?? ""
        }

        nsView.onAction { _ in
            self.action()
        }
    }
}

private var controlActionClosureProtocolAssociatedObjectKey: UInt8 = 0

protocol ControlActionClosureProtocol: NSObjectProtocol {
    var target: AnyObject? { get set }
    var action: Selector? { get set }
}

private final class ActionTrampoline<T>: NSObject {
    let action: (T) -> Void

    init(action: @escaping (T) -> Void) {
        self.action = action
    }

    @objc
    func action(sender: AnyObject) {
        action(sender as! T)
    }
}

extension ControlActionClosureProtocol {
    func onAction(_ action: @escaping (Self) -> Void) {
        let trampoline = ActionTrampoline(action: action)
        self.target = trampoline
        self.action = #selector(ActionTrampoline<Self>.action(sender:))
        objc_setAssociatedObject(self, &controlActionClosureProtocolAssociatedObjectKey, trampoline, .OBJC_ASSOCIATION_RETAIN)
    }
}

extension NSControl: ControlActionClosureProtocol {}

/// Guild popout window
/// Add parameters to show up
/// - guildID
/// - channelID
/// - channelName
/// TODO: Add better animation


func showWindow(guildID: String, channelID: String, channelName: String) {
    var windowRef: NSWindow
    windowRef = cuteWindow(
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

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

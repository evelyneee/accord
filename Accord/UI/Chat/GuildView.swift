//
//  GuildView.swift
//  Accord
//
//  Created by evelyn on 2020-11-27.
//


import SwiftUI
import AppKit

// styles and structs and vars

let messages = NetworkHandling()
let net = NetworkHandling()

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

struct GuildView: View {
    
    @Binding var clubID: String
    @Binding var channelID: String
    @Binding var channelName: String
    @State var chatTextFieldContents: String = ""
    @State var data: [Message] = []
    @State var sending: Bool = false
    @State var typing: [String] = []
    @State var collapsed: [Int] = []
    @State var pfpArray: [String:NSImage] = [:]
//    actual view begins here
    let timer = Timer.publish(every: 5, on: .current, in: .common).autoconnect()
    var body: some View {
//      chat view
        ZStack(alignment: .bottom) {
            Spacer()
            List {
                LazyVStack {
                    Spacer().frame(height: 93)
                    if (sending) && chatTextFieldContents != "" {
                        if let temp = chatTextFieldContents {
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
                                Button(action: {
                                }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(BorderlessButtonStyle())

                            }
                            .rotationEffect(.radians(.pi))
                            .scaleEffect(x: -1, y: 1, anchor: .center)
                            .opacity(0.75)

                        }
                    }
                    ForEach(data, id: \.self) { message in
                        if let index = data.firstIndex(of: message) {
                            VStack(alignment: .leading) {
                                if let reply = message.referenced_message {
                                    HStack {
                                        Spacer().frame(width: 50)
                                        Text("replying to ")
                                            .foregroundColor(.secondary)
                                        Attachment("https://cdn.discordapp.com/avatars/\(reply.author.id )/\(reply.author.avatar ?? "").png?size=80")
                                            .frame(width: 15, height: 15)
                                            .clipShape(Circle())
                                        HStack {
                                            if let author = reply.author.username {
                                                Text(author)
                                                    .fontWeight(.bold)
                                            }
                                        }
                                        if #available(macOS 12.0, *) {
                                            Text(try! AttributedString(markdown: reply.content))
                                                .lineLimit(0)
                                        } else {
                                            Text(reply.content)
                                                .lineLimit(0)

                                        }
                                    }
                                }
                                HStack(alignment: .top) {
                                    VStack {
                                        if index != data.count - 1 {
                                            if message.author.username != (data[Int(index + 1)].author.username) {
                                                Image(nsImage: pfpArray[message.author.id] ?? NSImage()).resizable()
                                                    .scaledToFit()
                                                    .frame(width: 33, height: 33)
                                                    .padding(.horizontal, 5)
                                                    .clipShape(Circle())
                                            }
                                        } else {
                                            Image(nsImage: pfpArray[message.author.id] ?? NSImage()).resizable()
                                                .scaledToFit()
                                                .frame(width: 33, height: 33)
                                                .padding(.horizontal, 5)
                                                .clipShape(Circle())
                                        }
                                    }
                                    VStack(alignment: .leading) {
                                        if index != data.count - 1 {
                                            if message.author.username == (data[Int(index + 1)].author.username) {
                                                FancyTextView(text: $data[index].content)
                                                    .padding(.leading, 50)
                                            } else {
                                                Text(message.author.username)
                                                    .fontWeight(.semibold)
                                                FancyTextView(text: $data[index].content)
                                            }
                                        } else {
                                            Text(message.author.username)
                                                .fontWeight(.semibold)
                                            FancyTextView(text: $data[index].content)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        DispatchQueue.main.async {
                                            NetworkHandling.shared.requestData(url: "\(rootURL)/channels/\(channelID)/messages/\(message.id)", token: token, json: false, type: .DELETE, bodyObject: [:]) { success, array in }
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())

                                }
                                if let attachment = message.attachments {
                                    if attachment.isEmpty == false {
                                        HStack {
                                            ForEach(0..<attachment.count, id: \.self) { index in
                                                if String((attachment[index].content_type ?? "").prefix(6)) == "image/" {
                                                    Attachment(attachment[index].url)
                                                        .cornerRadius(5)
                                                }

                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 45)
                                        .frame(maxWidth: 400, maxHeight: 300)
                                    }

                                }
                            }
                            .rotationEffect(.radians(.pi))
                            .scaleEffect(x: -1, y: 1, anchor: .center)
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
                if !(typing.isEmpty) {
                    if typing.count == 1 {
                        if var typingText = "\(typing.map{ "\($0)" }.joined(separator: ", ")) is typing..." {
                            VStack {
                                if #available(macOS 12.0, *) {
                                    Text("\(typing.map{ "\($0)" }.joined(separator: ", ")) is typing...")
                                        .padding(4)
                                        .background(.thickMaterial) // blurred background
                                        .cornerRadius(5)
                                } else {
                                    Text("\(typing.map{ "\($0)" }.joined(separator: ", ")) is typing...")
                                        .padding(4)
                                        .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                                        .cornerRadius(5)
                                }
                            }
                        }
                    } else {
                        if var typingText = "\(typing.map{ "\($0)" }.joined(separator: ", ")) are typing..." {
                            VStack {
                                if #available(macOS 12.0, *) {
                                    Text("\(typing.map{ "\($0)" }.joined(separator: ", ")) are typing...")
                                        .padding(4)
                                        .background(.thickMaterial) // blurred background
                                        .cornerRadius(5)
                                } else {
                                    Text("\(typing.map{ "\($0)" }.joined(separator: ", ")) are typing...")
                                        .padding(4)
                                        .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                                        .cornerRadius(5)
                                }
                            }
                        }
                    }


                }
                if #available(macOS 12.0, *) {
                    ChatControls(chatTextFieldContents: $chatTextFieldContents, data: $data, channelID: $channelID, chatText: Binding.constant("Message #\(channelName)"), sending: $sending)
                        .padding(15)
                        .background(.thickMaterial) // blurred background
                        .cornerRadius(15)
                } else {
                    ChatControls(chatTextFieldContents: $chatTextFieldContents, data: $data, channelID: $channelID, chatText: Binding.constant("Message #\(channelName)"), sending: $sending)
                        .padding(15)
                        .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                        .cornerRadius(15)
                }
            }
            .padding()

        }
        .onAppear {
            if clubID != "@me" {
                print(clubID)
                WebSocketHandler.shared.subscribe(clubID, channelID)
                WebSocketHandler.shared.getMembers(ids: ["700707501493977198"], guild: clubID) { success, users in
                    if success {
                        print(users)
                    }
                }
            }

            if token != "" {
                concurrentQueue.async {
                    NetworkHandling.shared.requestData(url: "\(rootURL)/channels/\(channelID)/messages?limit=100", token: token, json: true, type: .GET, bodyObject: [:]) { success, data in
                        if success == true {
                            do {
                                self.data = try JSONDecoder().decode([Message].self, from: data!)
                                ImageHandling.shared.getProfilePictures(array: self.data) { success, pfps in
                                    if success {
                                        pfpArray = pfps
                                        print(pfpArray)
                                    }
                                }
                            } catch {
                            }
                        }
                    }
                }
            }
        } /* Run everything into a separate queue so it doesn't clog the main thread */
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewMessageIn\(channelID)"))) { notif in
            concurrentQueue.async {
                sending = false
                if let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: notif.userInfo!["data"] as! Data) {
                    if let message = gatewayMessage.d {
                        data.insert(message, at: 0)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EditedMessageIn\(channelID)"))) { notif in
            concurrentQueue.async {
                let currentUIDDict = data.map { $0.id }
                if let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: notif.userInfo!["data"] as! Data) {
                    if let message = gatewayMessage.d {
                        data[(currentUIDDict).firstIndex(of: message.id) ?? 0] = message
                    }
                }

            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeletedMessageIn\(channelID)"))) { notif in
            concurrentQueue.async {
                let currentUIDDict = data.map { $0.id }
                if let gatewayMessage = try? JSONDecoder().decode(GatewayDeletedMessage.self, from: notif.userInfo!["data"] as! Data) {
                    if let message = gatewayMessage.d {
                        data.remove(at: (currentUIDDict).firstIndex(of: message.id) ?? 0)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TypingStartIn\(channelID)"))) { notif in
            print(notif.userInfo)
            print("TYPING")
            concurrentQueue.async {
                if !(typing.contains((notif.userInfo as? [AnyHashable:Any] ?? [:])["user_id"] as? String ?? "")) {
                    print("BAD OK")
                    if let member = ((notif.userInfo as? [AnyHashable:Any] ?? [:])["member"]) as? [String:Any] {
                        print("OK")
                        let memberData = try! JSONSerialization.data(withJSONObject: member, options: .prettyPrinted)
                        let memberDecodable = try! JSONDecoder().decode(GuildMember.self, from: memberData)
                        if let nick = memberDecodable.nick {
                            typing.append(nick)
                            DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
                                typing.remove(at: typing.firstIndex(of: (nick)) ?? 0)
                            })
                        } else {
                            typing.append(memberDecodable.user.username)
                            DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
                                typing.remove(at: typing.firstIndex(of: memberDecodable.user.username) ?? 0)
                            })
                        }
                    } else {
                        typing.append((notif.userInfo as? [AnyHashable:Any] ?? [:])["user_id"] as? String ?? "")
                        DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
                            typing.remove(at: typing.firstIndex(of: (notif.userInfo ?? [:])["user_id"] as? String ?? "") ?? 0)
                        })
                    }
                }
            } 
        }
    }
}

// Hide the TextField Focus Ring on Big Sur

extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}

struct ChatControls: View {
    @Binding var chatTextFieldContents: String 
    @State var textFieldContents: String = ""
    @Binding var data: [Message]
    @State var pfps: [String : NSImage] = [:]
    @Binding var channelID: String
    @Binding var chatText: String
    @Binding var sending: Bool
    @State var nitroless = false
    func refresh() {
        DispatchQueue.main.async {
            sending = false
            chatTextFieldContents = textFieldContents
        }
    }
    var body: some View {
        HStack {
            ZStack(alignment: .trailing) {
                TextField(chatText, text: $textFieldContents, onCommit: {
                    chatTextFieldContents = textFieldContents
                    let temp = textFieldContents
                    textFieldContents = ""
                    sending = true
                    DispatchQueue.main.async {
                        NetworkHandling.shared.request(url: "\(rootURL)/channels/\(channelID)/messages", token: token, json: false, type: .POST, bodyObject: ["content":"\(String(temp))"]) { success, array in
                            switch success {
                            case true:
                                break
                            case false:
                                print("whoop")
                                break
                            }
                        }
                    }
                })
                    .textFieldStyle(PlainTextFieldStyle())
                Button(action: {
                    nitroless.toggle()
                }) {
                    Image(systemName: "rectangle.grid.3x2.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                .popover(isPresented: $nitroless, content: {
                    NitrolessView(chatText: $chatTextFieldContents)
                        .frame(width: 300, height: 400)
                })
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


extension Array: Decodable where Element: Decodable {}

func showWindow(clubID: String, channelID: String, channelName: String) {
    var windowRef: NSWindow
    windowRef = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
        backing: .buffered, defer: false)
    windowRef.contentView = NSHostingView(rootView: GuildView(clubID: Binding.constant(clubID), channelID: Binding.constant(channelID), channelName: Binding.constant(channelName)))
    windowRef.minSize = NSSize(width: 500, height: 300)
    windowRef.isReleasedWhenClosed = false
    windowRef.makeKeyAndOrderFront(nil)
}

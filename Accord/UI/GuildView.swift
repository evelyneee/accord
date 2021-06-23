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


struct GuildView: View {
    @Binding var clubID: String
    @Binding var channelID: String
    @Binding var channelName: String
    @State var chatTextFieldContents: String = ""
    @State var data: [Message] = []
    @State var pfps: [String:NSImage] = [:]
    @State var sending: Bool = false
    @State var typing: [String] = []
//    actual view begins here
    func refresh() {
        pfps = ImageHandling.shared.getAllProfilePictures(array: data)
    }
    let timer = Timer.publish(every: 5, on: .current, in: .common).autoconnect()
    var body: some View {
//      chat view
        ZStack(alignment: .bottom) {
            Spacer()
            ZStack {
//                chat view
                List {
                    LazyVStack {
                        Spacer().frame(height: 75)
                        if (sending) && chatTextFieldContents != "" {
                            if let temp = chatTextFieldContents {
                                HStack {
                                    if pfpShown {
                                        Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                                            .frame(maxWidth: 33, maxHeight: 33)
                                            .scaledToFit()
                                            .padding(.horizontal, 5)
                                            .clipShape(Circle())
                                        VStack(alignment: .leading) {
                                            HStack {
                                                if let author = "\(username)" {
                                                    Text(author)
                                                        .fontWeight(.semibold)
                                                }
                                            }
                                            Text(temp)
                                        }
                                    } else {
                                        HStack {
                                            Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                                                .frame(maxWidth: 15, maxHeight: 15)
                                                .scaledToFit()
                                                .padding(.horizontal, 5)
                                                .clipShape(Circle())
                                            HStack {
                                                if let author = "\(username)" {
                                                    Text(author)
                                                        .fontWeight(.bold)

                                                }
                                            }

                                            Text(temp)
                                        }
                                    }
                                    Spacer()
                                    
                                }
                                .rotationEffect(.radians(.pi))
                                .scaleEffect(x: -1, y: 1, anchor: .center)
                                .opacity(0.75)
                            }
                        }
                        MessageCellView(clubID: $clubID, data: $data, pfps: $pfps, channelID: $channelID)
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
                .padding(.leading, -25.0)
                
            }
            .padding(.leading, 25.0)
            VStack(alignment: .leading) {
//                Text("\((typing.map { "\($0)" }.joined(separator: ", "))) are typing...")
                ChatControls(chatTextFieldContents: $chatTextFieldContents, data: $data, channelID: $channelID, chatText: Binding.constant("Message #\(channelName)"), sending: $sending)
                    .padding(15)
                    .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow))
                    .cornerRadius(15)
            }
            .padding()

        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewMessageIn\(channelID)"))) { notif in
            DispatchQueue.main.async {
                sending = false
                let encoder = JSONEncoder()
                data.insert(try! JSONDecoder().decode(GatewayMessage.self, from: notif.userInfo!["data"] as! Data).d!, at: 0)

                // data.insert(notif.userInfo as? [String:Any] ?? [:], at: 0)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TypingStartIn\(channelID)"))) { notif in
            // typing.append(notif.userInfo?["user_id"] as? String ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EditedMessageIn\(channelID)"))) { notif in
            DispatchQueue.main.async {
                let currentUIDDict = data.map { $0.id }
                // data[(currentUIDDict as? [String] ?? []).firstIndex(of: (notif.userInfo as? [String:Any] ?? [:])["id"] as? String ?? "error") ?? 0] = notif.userInfo as? [String:Any] ?? [:]
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeletedMessageIn\(channelID)"))) { notif in
            DispatchQueue.main.async {
                let currentUIDDict = data.map { $0.id }
                // data.remove(at: (currentUIDDict as! [String]).firstIndex(of: (notif.userInfo as? [String:Any] ?? [:])["id"] as! String) ?? 0)
            }
        }
        .onAppear {
            if token != "" {
                print("NewMessageIn\(channelID)")
                DispatchQueue.main.async {
                    NetworkHandling.shared.requestData(url: "\(rootURL)/channels/\(channelID)/messages?limit=100", token: token, json: true, type: .GET, bodyObject: [:]) { success, data in
                        if success == true {
                            self.data = try! JSONDecoder().decode([Message].self, from: data!)
                        }
                    }
                }
                net.requestData(url: "\(rootURL)/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in
                    print("request")
                    if let data = data {
                        let user = try! JSONDecoder().decode(User.self, from: data)
                        print(user.username, "HEYYY")
                    }
                }
            }
        }
    }
}

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
    func refresh() {
        DispatchQueue.main.async {
            sending = false
            chatTextFieldContents = textFieldContents
        }
    }
    var body: some View {
        HStack {
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

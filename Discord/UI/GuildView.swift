//
//  ClubView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-27.
//


import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// styles and structs and vars

let messages = NetworkHandling()
let net = NetworkHandling()
let parser = ParseMessages()

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


struct ClubView: View {
    
    @Binding var channelID: String
    @Binding var channelName: String
    @State var chatTextFieldContents: String = ""
    @State var data: [[String:Any]] = []
    @State var pfps: [String:NSImage] = [:]
    @State var allUsers: [String] = []
    @State var sending: Bool = false
    
//    actual view begins here
    func refresh() {
        DispatchQueue.main.async {
            NetworkHandling.shared.request(url: "\(rootURL)/channels/\(channelID)/messages", token: token, json: true, type: .GET, bodyObject: [:]) { success, array in
                if success == true {
                    data = array ?? []
                    pfps = ImageHandling.shared.getAllProfilePictures(array: data)
                }
            }
        }
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
//                                                    Text("#\(discriminator)")
//                                                        .foregroundColor(Color.secondary)
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
//                                                    Text("#\(discriminator)")
//                                                        .foregroundColor(Color.secondary)
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
                        MessageCellView(data: $data, pfps: $pfps, channelID: $channelID)
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
            HStack {
                ChatControls(chatTextFieldContents: $chatTextFieldContents, data: $data, channelID: $channelID, chatText: Binding.constant("Message #\(channelName)"), sending: $sending)
                    .padding(15)
                    .background(VisualEffectView(material: NSVisualEffectView.Material.appearanceBased, blendingMode: NSVisualEffectView.BlendingMode.withinWindow))
                    .cornerRadius(15)
//                #if os(iOS)
//                Button(action: {
//                    print("aa")
//                    DispatchQueue.main.async {
//                        NetworkHandling.shared.request(url: "\(rootURL)/channels/\(channelID)/messages", token: token, json: false, type: .POST, bodyObject: ["content":"\(String(chatTextFieldContents))"]) { success, array in
//                            switch success {
//                            case true:
//                                refresh()
//                                chatTextFieldContents = ""
//                            case false:
//                                print("whoop")
//                            }
//                        }
//                    }
//                }) {
//                    Image(systemName: "paperplane.fill")
//                }
//                .frame(width: 5, height: 5)
//                .ButtonStyle(BorderlessButtonStyle())
//                #endif
            }
            .padding()

        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewMessageIn\(channelID)"))) { notif in
            DispatchQueue.main.async {
                sending = false
                data.insert(notif.userInfo as? [String:Any] ?? [:], at: 0)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EditedMessageIn\(channelID)"))) { notif in
            DispatchQueue.main.async {
                let currentUIDDict = data.map { $0["id"] }
                data[(currentUIDDict as? [String] ?? []).index(of: (notif.userInfo as? [String:Any] ?? [:])["id"] as? String ?? "error") as? Int ?? 0] = notif.userInfo as? [String:Any] ?? [:]
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeletedMessageIn\(channelID)"))) { notif in
            DispatchQueue.main.async {
                let currentUIDDict = data.map { $0["id"] }
                data.remove(at: (currentUIDDict as! [String]).index(of: (notif.userInfo as? [String:Any] ?? [:])["id"] as! String)!)
//                data.insert(notif.userInfo as? [String:Any] ?? [:], at: 0)
            }
        }
        .onReceive(timer) { time in
            pfps = ImageHandling.shared.getAllProfilePictures(array: data)
        }
        .onAppear {
            if token != "" {
                print("NewMessageIn\(channelID)")
                DispatchQueue.main.async {
                    refresh()
                }
            }
        }
    }
}

struct ChatControls: View {
    @Binding var chatTextFieldContents: String
    @State var textFieldContents: String = ""
    @Binding var data: [[String:Any]]
    @State var pfps: [String : NSImage] = [:]
    @Binding var channelID: String
    @Binding var chatText: String
    @Binding var sending: Bool
    func refresh() {
        DispatchQueue.main.async {
            NetworkHandling.shared.request(url: "\(rootURL)/channels/\(channelID)/messages", token: token, json: true, type: .GET, bodyObject: [:]) { success, array in
                if success == true {
                    sending = false
                    chatTextFieldContents = textFieldContents
                    data = array ?? []
                }
            }
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

#if os(macOS)
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
#else
struct VisualEffectView: UIViewRepresentable {
    let material: UIVisualEffectView.Material
    let blendingMode: UIVisualEffectView.BlendingMode
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let visualEffectView = UIVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = UIVisualEffectView.State.active
        visualEffectView.shadow?.shadowBlurRadius = 20
        return visualEffectView
    }

    func updateUIView(_ visualEffectView: UIVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
#endif

//
//  ClubView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-27.
//


import SwiftUI
import Combine
import AppKit

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
    
//    actual view begins here
    func refresh() {
        DispatchQueue.main.async {
            NetworkHandling.shared.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, json: true, type: .GET, bodyObject: [:]) { success, array in
                if success == true {
                    data = array ?? []
                    pfps = ImageHandling.shared.getAllProfilePictures(array: array ?? [])
                }
            }
        }
    }
    let timer = Timer.publish(every: 3, on: .current, in: .common).autoconnect()
    var body: some View {
//      chat view
        ZStack(alignment: .bottom) {
            Spacer()
            ZStack {
//                chat view
                List {
                    LazyVStack {
                        Spacer().frame(height: 75)
                        ForEach(0..<parser.getArray(forKey: "content", messageDictionary: data).count, id: \.self) { index in
                            HStack {
                                if pfpShown {
                                    Image(nsImage: pfps[(parser.getArray(forKey: "user_id", messageDictionary: data)[safe: index] as! String)] ?? NSImage()).resizable()
                                        .frame(maxWidth: 33, maxHeight: 33)
                                        .scaledToFit()
                                        .padding(.horizontal, 5)
                                        .clipShape(Circle())
                                    VStack(alignment: .leading) {
                                        HStack {
                                            if let author = parser.getArray(forKey: "author", messageDictionary: data) {
                                                Text((author[index] as? String ?? "").dropLast(5))
                                                    .fontWeight(.bold)
                                                if (author[index] as? String ?? "").suffix(5) != "#0000" {
                                                    Text((author[index] as? String ?? "").suffix(5))
                                                        .foregroundColor(Color.secondary)
                                                }
                                                if (author[index] as? String ?? "").suffix(5) == "#0000" {
                                                    Text("Bot")
                                                        .fontWeight(.semibold)
                                                        .padding(2)
                                                        .background(Color.pink)
                                                        .cornerRadius(2)
                                                }
                                            }
                                        }
                                        Text(parser.getArray(forKey: "content", messageDictionary: data)[index] as? String ?? "")
                                    }
                                } else {
                                    HStack {
                                        HStack {
                                            if let author = parser.getArray(forKey: "author", messageDictionary: data) {
                                                Text((author[index] as? String ?? "").dropLast(5))
                                                    .fontWeight(.bold)
                                                if (author[index] as? String ?? "").suffix(5) != "#0000" {
                                                    Text((author[index] as? String ?? "").suffix(5))
                                                        .foregroundColor(Color.secondary)
                                                }
                                                if (author[index] as? String ?? "").suffix(5) == "#0000" {
                                                    Text("Bot")
                                                        .fontWeight(.semibold)
                                                        .padding(2)
                                                        .background(Color.pink)
                                                        .cornerRadius(2)
                                                }
                                            }
                                        }

                                        Text(parser.getArray(forKey: "content", messageDictionary: data)[index] as? String ?? "")
                                    }
                                }
                                Spacer()
                                Button(action: {
                                    DispatchQueue.main.async {
                                        let i = "https://constanze.live/api/v1/channels/\(channelID)/messages/\(parser.getArray(forKey: "id", messageDictionary: data)[index])"
                                        let index2 = index
                                        data.remove(at: index2)
                                        NetworkHandling.shared.requestData(url: i, token: token, json: false, type: .DELETE, bodyObject: [:]) {success, array in }
                                    }
                                }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                            }
                            .rotationEffect(.radians(.pi))
                            .scaleEffect(x: -1, y: 1, anchor: .center)
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
                            .padding()
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
                ChatControls(chatTextFieldContents: $chatTextFieldContents, data: $data, channelID: $channelID, chatText: Binding.constant("Message \(channelName)"))
                    .padding(15)
                    .background(VisualEffectView(material: NSVisualEffectView.Material.appearanceBased, blendingMode: NSVisualEffectView.BlendingMode.withinWindow))
                    .cornerRadius(15)
                #if os(iOS)
                Button(action: {
                    print("aa")
                    DispatchQueue.main.async {
                        NetworkHandling.shared.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, json: false, type: .POST, bodyObject: ["content":"\(String(chatTextFieldContents))"]) { success, array in
                            switch success {
                            case true:
                                refresh()
                                chatTextFieldContents = ""
                            case false:
                                print("whoop")
                            }
                        }
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                }
                .frame(width: 5, height: 5)
                .ButtonStyle(BorderlessButtonStyle())
                #endif
            }
            .padding()
        }
        .onReceive(timer) { time in
            DispatchQueue.main.async {
                refresh()
            }
        }
        .onAppear {
            if token != "" {
                DispatchQueue.main.async {
                    refresh()
                }
            }
        }
    }
}

struct ChatControls: View {
    @Binding var chatTextFieldContents: String
    @Binding var data: [[String:Any]]
    @State var pfps: [String : NSImage] = [:]
    @Binding var channelID: String
    @Binding var chatText: String
    func refresh() {
        DispatchQueue.main.async {
            NetworkHandling.shared.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, json: true, type: .GET, bodyObject: [:]) { success, array in
                if success == true {
                    data = array ?? []
                    pfps = ImageHandling.shared.getAllProfilePictures(array: array ?? [])
                }
            }
        }
    }
    var body: some View {
        HStack {
            TextField(chatText, text: $chatTextFieldContents, onCommit: {
                DispatchQueue.main.async {
                    NetworkHandling.shared.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, json: false, type: .POST, bodyObject: ["content":"\(String(chatTextFieldContents))"]) { success, array in
                        switch success {
                        case true:
                            refresh()
                            chatTextFieldContents = ""
                        case false:
                            print("whoop")
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

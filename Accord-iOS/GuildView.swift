//
//  ClubView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-27.
//


import SwiftUI
import UIKit

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
    @State var pfps: [String:UIImage] = [:]
    @State var allUsers: [String] = []
    @State var sending: Bool = false
    @State var textFieldContents: String = ""
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
                                        Image(uiImage: UIImage(data: avatar) ?? UIImage()).resizable()
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
                                            Image(uiImage: UIImage(data: avatar) ?? UIImage()).resizable()
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
                
            }
            HStack {
                ChatControls(chatTextFieldContents: $chatTextFieldContents, data: $data, channelID: $channelID, chatText: Binding.constant("Message #\(channelName)"), sending: $sending)
                    .padding()
            }
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
    @State var pfps: [String : UIImage] = [:]
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
            TextField(chatText, text: $textFieldContents)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: {
                print("aa")
                DispatchQueue.main.async {
                    NetworkHandling.shared.request(url: "\(rootURL)/channels/\(channelID)/messages", token: token, json: false, type: .POST, bodyObject: ["content":"\(String(chatTextFieldContents))"]) { success, array in
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
                    }
                }
            }) {
                Image(systemName: "paperplane.fill")
            }
            .frame(width: 5, height: 5)
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}


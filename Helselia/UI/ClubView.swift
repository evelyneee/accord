//
//  ClubView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-27.
//


import SwiftUI

// styles and structs and vars

var InputMsgIndex: Int = 0
var root: Int = 999999999999
let messages = NetworkHandling()
let net = NetworkHandling()
let parser = parseMessages()

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

// button style extension

extension Button {
    func coolButtonStyle() -> some View {
        self.buttonStyle(CoolButtonStyle())
    }
}

extension Dictionary {
    mutating func switchKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
}

// the messaging view concept

struct ClubView: View {
    
    
//    main variables for chat, will be migrated to backendClient later
    @Binding var clubID: String
    @Binding var channelID: String
    @State var chatTextFieldContents: String = ""
    @State var username = backendUsername
    @State public var ChannelKey = 1
    
//    message storing vars
    
    @State var MaxChannelNumber = 0
    @State var data: [[String:Any]] = []
    @State var pfps: [Any] = []
//    actual view begins here
    func refresh() {
        net.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, Cookie: "__cfduid=d9ee4b332e29b7a9b1e0befca2ac718461620217863", json: true, type: .GET, bodyObject: [:]) { success, array in
            if success == true {
                data = array ?? []
                pfps = parser.getArray(forKey: "avatar", messageDictionary: data)
            }
        }
    }
    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    var body: some View {
        
//      chat view
        VStack(alignment: .leading) {
            Spacer()
            HStack {
//                chat view
                List(0..<parser.getArray(forKey: "content", messageDictionary: data).count, id: \.self) { index in
                    HStack {
                        if !(pfps.isEmpty) {
                            if let imageURL = pfps[index] as? String {
                                ImageWithURL(imageURL)
                                    .frame(maxWidth: 33, maxHeight: 33)
                                    .padding(.horizontal, 5)
                                    .clipShape(Circle())
                            } else {
                                Image("pfp").resizable()
                                    .frame(maxWidth: 33, maxHeight: 33)
                                    .padding(.horizontal, 5)
                                    .clipShape(Circle())
                                    .scaledToFill()
                            }
                        } else {
                            Image("pfp").resizable()
                                .frame(maxWidth: 33, maxHeight: 33)
                                .padding(.horizontal, 5)
                                .clipShape(Circle())
                                .scaledToFill()
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text((parser.getArray(forKey: "author", messageDictionary: data)[index] as? String ?? "").dropLast(5))
                                    .fontWeight(.bold)
                                if (parser.getArray(forKey: "author", messageDictionary: data)[index] as? String ?? "").suffix(5) != "#0000" {
                                    Text((parser.getArray(forKey: "author", messageDictionary: data)[index] as? String ?? "").suffix(5))
                                        .foregroundColor(Color.secondary)
                                }
                                if (parser.getArray(forKey: "author", messageDictionary: data)[index] as? String ?? "").suffix(5) == "#0000" {
                                    Text("Bot")
                                        .fontWeight(.semibold)
                                        .padding(2)
                                        .background(Color.pink)
                                        .cornerRadius(2)
                                }
                            }
                            Text(parser.getArray(forKey: "content", messageDictionary: data)[index] as? String ?? "")
                        }
                        Spacer()
                        Button(action: {
                            print("https://constanze.live/api/v1/channels/\(channelID)/messages/\(parser.getArray(forKey: "id", messageDictionary: data)[index])")
                            net.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages/\(parser.getArray(forKey: "id", messageDictionary: data)[index])", token: token, Cookie: "__cfduid=d9ee4b332e29b7a9b1e0befca2ac718461620217863", json: false, type: .DELETE, bodyObject: [:]) {success, array in }
                            refresh()
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .rotationEffect(.radians(.pi))
                    .scaleEffect(x: -1, y: 1, anchor: .center)
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                .padding([.leading, .top], -25.0)
                .padding(.bottom, -9.0)
                
                
            }
            .padding(.leading, 25.0)
            
//            the controls
            
            HStack(alignment: .bottom) {
                TextField("What's up?", text: $chatTextFieldContents)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(EdgeInsets())

//                where messages are sent
                
                Button(action: {
                    var tempTextField = chatTextFieldContents
                    chatTextFieldContents = ""
                    DispatchQueue.main.async {
                        net.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, Cookie: "__cfduid=d9ee4b332e29b7a9b1e0befca2ac718461620217863", json: false, type: .POST, bodyObject: ["content":"\(String(tempTextField))"]) {success, array in
                            switch success {
                            case true:
                                refresh()
                            case false:
                                print("whoop")
                            }
                        }
                        print("done")
                        tempTextField = ""
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(Color.white)
            }
            .padding()
        }
        .onAppear {
            if token != "" {
                print("token found \(token)")
                DispatchQueue.main.async {
                    refresh()
                }
            }
        }
    }
}

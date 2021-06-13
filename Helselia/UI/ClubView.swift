//
//  ClubView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-27.
//


import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// styles and structs and vars

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

// the messaging view concept

struct ClubView: View {
    
    
    @Binding var channelID: String
    @State var chatTextFieldContents: String = ""
    @State var data: [[String:Any]] = []
    @State var pfps: [Any] = []
    @State var allUsers: [String] = []
    
//    actual view begins here
    func refresh() {
        DispatchQueue.main.async {
            NetworkHandling.shared.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, json: true, type: .GET, bodyObject: [:]) { success, array in
                if success == true {
                    data = array ?? []
                    pfps = parser.getArray(forKey: "avatar", messageDictionary: data)
                }
            }
        }
    }
    let timer = Timer.publish(every: 3, on: .current, in: .common).autoconnect()
    var body: some View {
//      chat view
        VStack(alignment: .leading) {
            Spacer()
            HStack {
//                chat view
                List(0..<parser.getArray(forKey: "content", messageDictionary: data).count, id: \.self) { index in
                    HStack {
                        if let imageURL = pfps[safe: index] as? String {
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
                            DispatchQueue.main.async {
                                NetworkHandling.shared.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages/\(parser.getArray(forKey: "id", messageDictionary: data)[index])", token: token, json: false, type: .DELETE, bodyObject: [:]) {success, array in }
                            }
                            print("https://constanze.live/api/v1/channels/\(channelID)/messages/\(parser.getArray(forKey: "id", messageDictionary: data)[index])")
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
            
            ChatControls(chatTextFieldContents: $chatTextFieldContents, data: $data, channelID: $channelID)
        }
        .onReceive(timer) { time in
            DispatchQueue.main.async {
                NetworkHandling.shared.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, json: true, type: .GET, bodyObject: [:]) { success, array in
                    if success == true {
                        data = array ?? []
                    }
                }
            }
        }
        .onReceiveNotifs(Notification.Name(rawValue: "logged_in")) { _ in
            print("logged in")
            refresh()
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
    @State var pfps: [Any] = []
    @Binding var channelID: String
    func refresh() {
        DispatchQueue.main.async {
            NetworkHandling.shared.request(url: "https://constanze.live/api/v1/channels/\(channelID)/messages", token: token, json: true, type: .GET, bodyObject: [:]) { success, array in
                if success == true {
                    data = array ?? []
                    pfps = parser.getArray(forKey: "avatar", messageDictionary: data)
                }
            }
        }
    }
    var body: some View {
        HStack {

            #if os(iOS)
            TextField("What's up?", text: $chatTextFieldContents)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(EdgeInsets())
            #else
            BorderlessTextField(placeholder: "What's up?", text: $chatTextFieldContents, isFocus: Binding.constant(false))
                .cornerRadius(5)
                .padding(EdgeInsets())
            #endif
            Button(action: {
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
                    print("done")
                }
            }) {
                Image(systemName: "paperplane.fill")
            }
            .frame(width: 0, height: 0)
            .keyboardShortcut(.defaultAction)
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(Color.clear)
            .opacity(0)
        }
        .padding()
    }
}

#if os(macOS)
struct BorderlessTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    @Binding var isFocus: Bool
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.focusRingType = .none
        textField.bezelStyle = NSTextField.BezelStyle.roundedBezel
        return textField
    }
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: BorderlessTextField
        init(_ textField: BorderlessTextField) {
            self.parent = textField
        }
        func controlTextDidEndEditing(_ obj: Notification) {
            self.parent.isFocus = false
        }
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            self.parent.text = textField.stringValue
        }
    }
}
#endif


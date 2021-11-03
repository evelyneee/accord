//
//  ChatControlsView.swift
//  ChatControlsView
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

struct ChatControls: View {
    @Binding var chatTextFieldContents: String
    @State var textFieldContents: String = ""
    @State var pfps: [String : NSImage] = [:]
    @Binding var channelID: String
    @Binding var chatText: String
    @Binding var sending: Bool
    @Binding var replyingTo: Message?
    @Binding var editing: String?
    @State var nitroless = false
    @State var emotes = false
    @State var temporaryText = ""
    @State var fileImport: Bool = false
    @State var fileUpload: Data? = nil
    @State var fileUploadURL: URL? = nil
    @State var dragOver: Bool = false
    @State var pluginPoppedUp: [Bool] = []
    
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
                TextField(chatText, text: $textFieldContents, onEditingChanged: { state in
                    Networking<AnyDecodable>().fetch(url: URL(string: "https://discord.com/api/v9/channels/\(channelID)/typing"), headers: Headers(
                        userAgent: discordUserAgent,
                        token: AccordCoreVars.shared.token,
                        type: .POST,
                        discordHeaders: true
                    )) { _ in }
                }, onCommit: {
                    chatTextFieldContents = textFieldContents
                    var temp = textFieldContents
                    textFieldContents = ""
                    sending = true
                    let messageSendQueue = DispatchQueue(label: "Send Message")
                    messageSendQueue.async {
                        if temp == "/shrug" {
                            temp = #"¯\_(ツ)_/¯"#
                        }
                        if (editing != nil) {
                            print(editing ?? "")
                            Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages/\(editing ?? "")"), headers: Headers(
                                userAgent: discordUserAgent,
                                token: AccordCoreVars.shared.token,
                                bodyObject: ["content":"\(String(temp))"],
                                type: .PATCH,
                                discordHeaders: true,
                                empty: true
                            )) { _ in }
                            editing = nil
                        } else {
                            if fileUpload != nil {
                                uploadFile(temp: temp)
                                fileUpload = nil
                                fileUploadURL = nil
                            } else {
                                if replyingTo != nil {
                                    Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages"), headers: Headers(
                                        userAgent: discordUserAgent,
                                        token: AccordCoreVars.shared.token,
                                        bodyObject: ["content":"\(String(temp))", "allowed_mentions":["parse":["users","roles","everyone"], "replied_user":true], "message_reference":["channel_id":channelID, "message_id":replyingTo?.id ?? ""]],
                                        type: .POST,
                                        discordHeaders: true,
                                        empty: true,
                                        json: true
                                    )) { _ in }
                                    replyingTo = nil
                                } else {
                                    Networking<AnyDecodable>().fetch(url: URL(string: "\(rootURL)/channels/\(channelID)/messages"), headers: Headers(
                                        userAgent: discordUserAgent,
                                        token: AccordCoreVars.shared.token,
                                        bodyObject: ["content":"\(String(temp))"],
                                        type: .POST,
                                        discordHeaders: true,
                                        empty: true
                                    )) { _ in }
                                }

                            }
                        }


                    }
                })
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
                            fileUpload = data
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
                    .keyboardShortcut("e", modifiers: [.command])
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

extension Data {
    mutating func append(string: String, encoding: String.Encoding) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}

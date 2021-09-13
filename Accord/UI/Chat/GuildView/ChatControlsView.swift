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
    @State var nitroless = false
    @State var emotes = false
    @State var temporaryText = ""
    @State var fileImport: Bool = false
    @State var fileUpload: Data? = nil
    @State var fileUploadURL: URL? = nil
    @State var dragOver: Bool = false
    func refresh() {
        DispatchQueue.main.async {
            sending = false
            chatTextFieldContents = textFieldContents
        }
    }
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
            if let data = data {
                print(String(data: data, encoding: .utf8) as Any, "RESPONDED")
            }
        }).resume()
    }
    
    var body: some View {
        HStack {
            ZStack(alignment: .trailing) {
                TextField(chatText, text: $textFieldContents, onEditingChanged: { state in
                         NetworkHandling.shared.emptyRequest(url: "https://discord.com/api/v9/channels/\(channelID)/typing", token: AccordCoreVars.shared.token, json: false, type: .POST, bodyObject: [:])
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
                        if fileUpload != nil {
                            uploadFile(temp: temp)
                            fileUpload = nil
                            fileUploadURL = nil
                        } else {
                            if replyingTo != nil {
                                NetworkHandling.shared.emptyRequest(url: "\(rootURL)/channels/\(channelID)/messages", token: AccordCoreVars.shared.token, json: true, type: .POST, bodyObject: ["content":"\(String(temp))", "allowed_mentions":["parse":["users","roles","everyone"], "replied_user":true], "message_reference":["channel_id":channelID, "message_id":replyingTo?.id ?? ""]])
                                replyingTo = nil
                            } else {
                                NetworkHandling.shared.emptyRequest(url: "\(rootURL)/channels/\(channelID)/messages", token: AccordCoreVars.shared.token, json: false, type: .POST, bodyObject: ["content":"\(String(temp))"])
                            }

                        }

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

extension Data {
    mutating func append(string: String, encoding: String.Encoding) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}

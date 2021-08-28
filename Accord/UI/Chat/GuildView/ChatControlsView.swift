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
                            NetworkHandling.shared?.emptyRequest(url: "\(rootURL)/channels/\(channelID)/messages",  token: AccordCoreVars.shared.token, json: false, type: .POST, bodyObject: ["payload_json":["content":"\(String(temp))"], "file":fileUpload as Any])
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

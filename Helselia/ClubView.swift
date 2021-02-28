//
//  ClubView.swift
//  Helselia
//
//  Created by althio on 2020-11-27.
//
// SNOWFLAKES
// Structure: TIMESTAMP MESSAGE USER CHANNEL
//
// Root Number
// 999999999999
// aka 12x the number 9


import SwiftUI

// styles and structs and vars

var InputMsgIndex: Int = 0
var root: Int = 999999999999
let messages = GetMessages()

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
    
    @State var chatTextFieldContents: String = ""
    @State var username = backendUsername
    @State public var msgArray: Array = ["test"]
    
    @State public var ChannelKey = 1
    
//    message storing vars
    
    @State var MaxChannelNumber = 0
    @State var userID = 999999999999
    @State var channelID = 999999999999
    
    @State public var messageStorage: [String: String] = [:]
    
//    althio's function collection
    
//    who are you
    
    public func WhoAreYou(userID: Int) -> String {
        if userID == 999999999999 {
            return backendUsername
        } else {
            return "Deleted User \(userID)"
        }
    }
    
//    Message Sending
    
    public func sendMessage(IDChannel: Int) {
        if chatTextFieldContents != "" && chatTextFieldContents != " " {
            messageStorage["\(generateSnowflakes(userID: 999999999999, channelID: IDChannel, messageID: Int(1000000000000 - (messageStorage.count + 1))))"] = chatTextFieldContents
            chatTextFieldContents = ""
        }
    }
    
//    grab number of messages marching channel ID
    
    public func messageCountInChannel(channelID: Int) -> Int {
        var outputFilteredMessagesMatchingChannel: [String] = []
        
        for snowflakeReg in messageStorage.keys {
            if parseSnowflakes(output: .channelID, snowflake: snowflakeReg).contains(String(channelID)) {
                outputFilteredMessagesMatchingChannel.append(snowflakeReg)
            }
        }
        return outputFilteredMessagesMatchingChannel.count
    }
    
//    get message content to display
    
    public func findMessageContent(messageSituation: Int, channelLocation: Int) -> String {
        var messageContents = ""
        for snowflake in messageStorage.keys {
            if parseSnowflakes(output: .channelID, snowflake: snowflake) == String(channelLocation) {
                if String(messageSituation) == parseSnowflakes(output: .messageID, snowflake: snowflake) {
                    messageContents = messageStorage[snowflake] ?? "error"
                }
            }
        }
        return messageContents
    }
    
//    realign .messageID after deleting message
    
    public func switchToMinusOne(snowflake: String) -> String {
        var addingOne: Int
        if parseSnowflakes(output: .messageID, snowflake: snowflake) != "999999999999" {
            addingOne = 1 + Int(parseSnowflakes(output: .messageID, snowflake: snowflake))!
        } else {
            addingOne = 999999999999
        }
        print(addingOne)
        return parseSnowflakes(output: .timestamp, snowflake: snowflake) + String(addingOne) + parseSnowflakes(output: .userID, snowflake: snowflake) + parseSnowflakes(output: .channelID, snowflake: snowflake)
    }
    
//    remove message
    
    public func removeMessage(messageSituation: Int, channelLocation: Int) {
//      get snowflake to process here
        for snowflake in messageStorage.keys {
//          check if processing number matches when passing through keys
            if parseSnowflakes(output: .channelID, snowflake: snowflake) == String(channelLocation) {
//              second check here
                if String(messageSituation) == parseSnowflakes(output: .messageID, snowflake: snowflake) {
//                  remove message and realign keys for .messageID
                    messageStorage.removeValue(forKey: snowflake)
                    if 999999999999 - messageSituation != messageStorage.count {
                        for messageNumber in (999999999999 - messageSituation)...(messageStorage.count - 1) {
                            let currentMessage = 999999999999 - messageNumber
                            let messageToSwitchFrom = currentMessage - 1
                            messageStorage.switchKey(fromKey: (parseSnowflakes(output: .timestamp, snowflake: snowflake) + String(messageToSwitchFrom) + parseSnowflakes(output: .userID, snowflake: snowflake) + parseSnowflakes(output: .channelID, snowflake: snowflake)), toKey: (parseSnowflakes(output: .timestamp, snowflake: snowflake) + String(currentMessage) + parseSnowflakes(output: .userID, snowflake: snowflake) + parseSnowflakes(output: .channelID, snowflake: snowflake)))
                        }
                    }
                }
            }
        }
    }
    
//    actual view begins here
    
    var body: some View {
        
//      chat view
        
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                
//                chat view
                
                List(0..<Int(messageCountInChannel(channelID: 999999999999)), id: \.self) { msgIndex in
                    HStack {
                        if enablePFP == true {
//                          Main style, like any messaging app
                            Image("pfp").resizable()
                                .frame(maxWidth: 33, maxHeight: 33)
                                .clipShape(Circle())
                                .padding(.horizontal, 5)
                                .scaledToFill()
                            VStack(alignment: .leading) {
                                Text(WhoAreYou(userID: 999999999999))
                                        .fontWeight(.bold)
                                        .padding(EdgeInsets())
                                Text(findMessageContent(messageSituation: 999999999999 - msgIndex, channelLocation: 999999999999))
                            }
                            Spacer()
                            Button(action: {
                                removeMessage(messageSituation: 999999999999 - msgIndex, channelLocation: 999999999999)
                                backendMessageStorage = messageStorage
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        } else {
//                          IRC Style
                            HStack(alignment: .top) {
                                Text(WhoAreYou(userID: 999999999999))
                                        .fontWeight(.bold)
                                        .padding(EdgeInsets())
                                Text(findMessageContent(messageSituation: 999999999999 - msgIndex, channelLocation: 999999999999))
                                Spacer()
                                Button(action: {
                                    removeMessage(messageSituation: 999999999999 - msgIndex, channelLocation: 999999999999)
                                    backendMessageStorage = messageStorage
                                }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }


                }
                .padding([.leading, .top], -25.0)
                .padding(.bottom, -9.0)
                
                
            }
            .padding(.leading, 25.0)
            
//            the controls part, easy
            
            HStack(alignment: .bottom) {
                TextField("What's wrong?", text: $chatTextFieldContents)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(EdgeInsets())

//                where messages are sent
                
                Button(action: {
                    sendMessage(IDChannel: 999999999999)
                    backendMessageStorage = messageStorage
                }) {
                    Image(systemName: "paperplane.fill")
                }
                .coolButtonStyle()
                .shadow(radius: 2)
            }
            .padding()
        }
        .onAppear {
            messageStorage = backendMessageStorage
            messages.restructureToMessage(array: messages.getMessageArray(url: "https://constanze.live/api/v1/channels/148502836349636615/messages", Bearer: "Bearer MTQ4Mjg1NjMwNDI0NjgyNDk2.YCedEQ.QAXCkOGcqHRozfA4bDLrpA6ty9w", Cookie: "__cfduid=d7ec9d856babfb5509db14c7da55eaf4f1614381301"))
        }
    }
}

struct ClubView_Previews: PreviewProvider {
    static var previews: some View {
        ClubView()
    }
}

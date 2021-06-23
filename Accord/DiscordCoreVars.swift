//
//  backendClient.swift
//  Accord
//
//  Created by evelyn on 2020-11-27.
//

import Foundation

//public let rootURL: String = "https://constanze.live/api/v1"
//public let gatewayURL: String = "wss://gateway.constanze.live"
public let rootURL: String = "https://discord.com/api/v9"
public let gatewayURL: String = "wss://gateway.discord.gg"
public let cdnURL: String = "https://cdn.discordapp.com"
public var user_id: String = ""
public var avatar: Data = Data()
public var pfpShown: Bool = UserDefaults.standard.bool(forKey: "pfpShown")
public var username: String = ""
public var discriminator: String = ""
public var token: String = String(decoding: KeychainManager.load(key: "token") ?? Data(), as: UTF8.self)

/*struct MessageCellView: View {
    @Binding var clubID: String
    @Binding var data: [Message]
    @Binding var pfps: [String:NSImage]
    @Binding var channelID: String
    @State var collapsed: [Int] = []
    var body: some View {
        ForEach(0..<data.count, id: \.self) { index in
            if let message = data[index] as? Message {
                VStack(alignment: .leading) {

                    HStack(alignment: .top) {
                        if let author = message.author.username as? String {
                            if pfpShown {
                                if index != data.count - 1 {
                                    if author != (data[Int(index + 1)].author.id) {
                                        Image(nsImage: pfps[message.author.id] ?? NSImage()).resizable()
                                            .frame(width: 33, height: 33)
                                            .scaledToFit()
                                            .padding(.horizontal, 5)
                                            .clipShape(Circle())
                                    }
                                } else {
                                    Image(nsImage: pfps[message.author.id] ?? NSImage()).resizable()
                                        .frame(width: 33, height: 33)
                                        .scaledToFit()
                                        .padding(.horizontal, 5)
                                        .clipShape(Circle())
                                }
                                VStack(alignment: .leading) {
                                    HStack {
                                        if index != data.count - 1 {
                                            if author != (data[Int(index + 1)].author.id) {
                                                Text(author)
                                                    .fontWeight(.semibold)
                                            }
                                        } else {
                                            Text(author)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    FancyTextView(text: Binding.constant(message.content))

                                }
                                Spacer()
                                Button(action: {
                                    if collapsed.contains(index) {
                                        collapsed.remove(at: collapsed.firstIndex(of: index)!)
                                    } else {
                                        collapsed.append(index)
                                    }
                                }) {
                                    Image(systemName: ((collapsed.contains(index)) ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                if (collapsed.contains(index)) {
                                    Button(action: {
                                        DispatchQueue.main.async {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(message.content, forType: .string)
                                            if collapsed.contains(index) {
                                                collapsed.remove(at: collapsed.firstIndex(of: index)!)
                                            } else {
                                                collapsed.append(index)
                                            }
                                        }
                                    }) {
                                        Text("Copy")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    Button(action: {
                                        DispatchQueue.main.async {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString("https://discord.com/channels/\(clubID)/\(channelID)/\(message.id)", forType: .string)
                                            if collapsed.contains(index) {
                                                collapsed.remove(at: collapsed.firstIndex(of: index)!)
                                            } else {
                                                collapsed.append(index)
                                            }
                                        }
                                    }) {
                                        Text("Copy Message Link")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                Button(action: {
                                    DispatchQueue.main.async {
                                        let i = "\(rootURL)/channels/\(channelID)/messages/\(message.id)"
                                        NetworkHandling.shared.requestData(url: i, token: token, json: false, type: .DELETE, bodyObject: [:]) { success, array in }
                                    }
                                }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }

                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
            }
        }
        .onAppear(perform: {
            DispatchQueue.main.async {
                pfps = ImageHandling.shared.getAllProfilePictures(array: data)
                print(data, "HERE")
            }
        })
    }
}*/

//
//  MessagesView.swift
//  Accord
//
//  Created by evelyn
//

import SwiftUI
import Foundation

struct MessageCellView: View {
    @Binding var clubID: String
    @Binding var data: [Message]
    @Binding var channelID: String
    @State var collapsed: [Int] = []
    @Binding var sending: Bool
    var body: some View {
        ForEach(0..<data.count, id: \.self) { index in
            if let message = data[index] {
                VStack(alignment: .leading) {
                    if let reply = message.referenced_message {
                        HStack {
                            Spacer().frame(width: 50)
                            Text("replying to ")
                                .foregroundColor(.secondary)
                            Attachment("https://cdn.discordapp.com/avatars/\(reply.author.id )/\(reply.author.avatar ?? "").png?size=80")
                                .frame(width: 15, height: 15)
                                .padding(.horizontal, 5)
                                .clipShape(Circle())
                            HStack {
                                if let author = reply.author.username as? String {
                                    Text(author)
                                        .fontWeight(.bold)
                                }
                            }
                            if #available(macOS 12.0, *) {
                                Text(try! AttributedString(markdown: reply.content))
                                    .lineLimit(0)
                            } else {
                                Text(reply.content)
                                    .lineLimit(0)

                            }
                        }
                    }
                    HStack(alignment: .top) {
                        if let author = message.author.username as? String {
                            if pfpShown {
                                VStack {
                                    if index != data.count - 1 {
                                        if author != (data[Int(index + 1)].author.username ?? "") {
                                            Attachment("https://cdn.discordapp.com/avatars/\(message.author.id )/\(message.author.avatar ?? "").png?size=80")
                                                .frame(width: 33, height: 33)
                                                .padding(.horizontal, 5)
                                                .clipShape(Circle())
                                        }
                                    } else {
                                        Attachment("https://cdn.discordapp.com/avatars/\(message.author.id )/\(message.author.avatar ?? "").png?size=80")
                                            .frame(width: 33, height: 33)
                                            .padding(.horizontal, 5)
                                            .clipShape(Circle())
                                    }
                                }
                                VStack(alignment: .leading) {
                                    if index != data.count - 1 {
                                        if author == (data[Int(index + 1)].author.username ?? "") {
                                            FancyTextView(text: Binding.constant(message.content))
                                                .padding(.leading, 50)
                                        } else {
                                            Text(author)
                                                .fontWeight(.semibold)
                                            FancyTextView(text: Binding.constant(message.content))
                                        }
                                    } else {
                                        Text(author)
                                            .fontWeight(.semibold)
                                        FancyTextView(text: Binding.constant(message.content))
                                    }
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
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(message.content, forType: .string)
                                        collapsed.remove(at: collapsed.firstIndex(of: index)!)
                                    }) {
                                        Text("Copy")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    Button(action: {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString("https://discord.com/channels/\(clubID)/\(channelID)/\(message.id)", forType: .string)
                                        collapsed.remove(at: collapsed.firstIndex(of: index)!)
                                    }) {
                                        Text("Copy Message Link")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                Button(action: {
                                    DispatchQueue.main.async {
                                        NetworkHandling.shared.requestData(url: "\(rootURL)/channels/\(channelID)/messages/\(message.id)", token: token, json: false, type: .DELETE, bodyObject: [:]) { success, array in }
                                    }
                                }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(BorderlessButtonStyle())

                            }
                        }
                    }
                    if let attachment = message.attachments {
                        if attachment.isEmpty == false {
                            HStack {
                                ForEach(0..<attachment.count, id: \.self) { index in
                                    Attachment(attachment[index].url)
                                        .cornerRadius(5)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 45)
                            .frame(maxWidth: 400, maxHeight: 300)
                        }
                    }
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
            }
        }

    }
}



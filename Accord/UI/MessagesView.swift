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
    @Binding var data: [[String:Any]]
    @Binding var pfps: [String:NSImage]
    @Binding var channelID: String
    @State var collapsed: [Int] = []
    var body: some View {
        ForEach(Array((data.map { $0["content"] } as? [String] ?? []).enumerated()), id: \.offset) { offset, content in
            VStack(alignment: .leading) {
                if let reply = data[offset]["referenced_message"] as? [String:Any] {
                    HStack {
                        Spacer().frame(width: 50)
                        Text("replying to ")
                            .foregroundColor(.secondary)
                        Image(nsImage: pfps[(reply["author"] as? [String:Any] ?? [:])["id"] as? String ?? ""] ?? NSImage()).resizable()
                            .frame(width: 15, height: 15)
                            .scaledToFit()
                            .clipShape(Circle())
                        HStack {
                            if let author = (reply["author"] as? [String:Any] ?? [:])["username"] as? String {
                                Text(author)
                                    .fontWeight(.bold)
                            }
                        }
                        if #available(macOS 12.0, *) {
                            Text(try! AttributedString(markdown: reply["content"] as? String ?? ""))
                                .lineLimit(1)
                        } else {
                            Text(reply["content"] as? String ?? "")
                                .lineLimit(1)

                        }
                    }
                }
                HStack(alignment: .top) {
                    if pfpShown {
                        Image(nsImage: pfps[(data[offset]["author"] as? [String:Any] ?? [:])["id"] as? String ?? ""] ?? NSImage()).resizable()
                            .frame(width: 33, height: 33)
                            .scaledToFit()
                            .padding(.horizontal, 5)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            HStack {
                                if let author = (data[offset]["author"] as? [String:Any] ?? [:])["username"] as? String {
                                    Text(author)
                                        .fontWeight(.semibold)
                                }
                            }
                            if #available(macOS 12.0, *) {
                                Text(try! AttributedString(markdown: content))
                            } else {
                                Text(content)
                            }
                        }
                        Spacer()
                        Button(action: {
                            if collapsed.contains(offset) {
                                collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                            } else {
                                collapsed.append(offset)
                            }
                        }) {
                            Image(systemName: ((collapsed.contains(offset)) ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        if (collapsed.contains(offset)) {
                            Button(action: {
                                DispatchQueue.main.async {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(content, forType: .string)
                                    if collapsed.contains(offset) {
                                        collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                                    } else {
                                        collapsed.append(offset)
                                    }
                                }
                            }) {
                                Text("Copy")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            Button(action: {
                                DispatchQueue.main.async {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("https://discord.com/channels/\(clubID)/\(channelID)/\((data.map { $0["id"] as? String ?? "" })[offset])", forType: .string)
                                    if collapsed.contains(offset) {
                                        collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                                    } else {
                                        collapsed.append(offset)
                                    }
                                }
                            }) {
                                Text("Copy Message Link")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        Button(action: {
                            DispatchQueue.main.async {
                                let i = "\(rootURL)/channels/\(channelID)/messages/\((data.map { $0["id"] as? String ?? "" })[offset])"
                                NetworkHandling.shared.requestData(url: i, token: token, json: false, type: .DELETE, bodyObject: [:]) { success, array in }
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    } else {
                        HStack {
                            Image(nsImage: pfps[(data[offset]["author"] as? [String:Any] ?? [:])["id"] as? String ?? ""] ?? NSImage()).resizable()
                                .frame(width: 15, height: 15)
                                .scaledToFit()
                                .padding(.horizontal, 5)
                                .clipShape(Circle())
                            HStack {
                                if let author = (data[offset]["author"] as? [String:Any] ?? [:])["username"] as? String {
                                    Text(author)
                                        .fontWeight(.semibold)
                                }
                            }

                            if #available(macOS 12.0, *) {
                                Text(try! AttributedString(markdown: content))
                            } else {
                                Text(content)
                            }
                            Spacer()
                            Button(action: {
                                if collapsed.contains(offset) {
                                    collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                                } else {
                                    collapsed.append(offset)
                                }
                            }) {
                                Image(systemName: ((collapsed.contains(offset)) ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            if (collapsed.contains(offset)) {
                                Button(action: {
                                    DispatchQueue.main.async {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(content, forType: .string)
                                        if collapsed.contains(offset) {
                                            collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                                        } else {
                                            collapsed.append(offset)
                                        }
                                    }
                                }) {
                                    Text("Copy")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                Button(action: {
                                    DispatchQueue.main.async {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString("https://discord.com/channels/\(clubID)/\(channelID)/\((data.map { $0["id"] as? String ?? "" })[offset])", forType: .string)
                                        if collapsed.contains(offset) {
                                            collapsed.remove(at: collapsed.firstIndex(of: offset)!)
                                        } else {
                                            collapsed.append(offset)
                                        }
                                    }
                                }) {
                                    Text("Copy Message Link")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            Button(action: {
                                DispatchQueue.main.async {
                                    let i = "\(rootURL)/channels/\(channelID)/messages/\((data.map { $0["id"] as? String ?? "" })[offset])"
                                    NetworkHandling.shared.requestData(url: i, token: token, json: false, type: .DELETE, bodyObject: [:]) { success, array in }
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(BorderlessButtonStyle())

                        }
                    }
                }
                .id(offset)
                if let attachment = data[offset]["attachments"] as? [[String:Any]] {
                    if attachment.isEmpty == false {
                        HStack {
                            ForEach(0..<attachment.count, id: \.self) { index in
                                Attachment(attachment[index]["url"] as! String)
                                    .frame(maxWidth: 400, maxHeight: 300)
                                    .cornerRadius(10)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 45)
                    }
                }
            }
            .rotationEffect(.radians(.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
            .onAppear(perform: {
                DispatchQueue.main.async {
                    pfps = ImageHandling.shared.getAllProfilePictures(array: data)
                }
            })
        }

    }
}


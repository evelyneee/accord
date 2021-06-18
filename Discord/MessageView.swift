//
//  discordlib.swift
//  Discord
//
//  Created by evelyn
//

import SwiftUI
import Foundation

struct MessageCellView: View {
    @Binding var data: [[String:Any]]
    @Binding var pfps: [String:NSImage]
    @Binding var channelID: String
    var body: some View {
        ForEach(Array((parser.getArray(forKey: "content", messageDictionary: data) as? [String] ?? []).enumerated()), id: \.offset) { offset, content in
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    if pfpShown {
                        Image(nsImage: pfps[(parser.getArray(forKey: "user_id", messageDictionary: data)[safe: offset] as! String)] ?? NSImage()).resizable()
                            .frame(maxWidth: 33, maxHeight: 33)
                            .scaledToFit()
                            .padding(.horizontal, 5)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            HStack {
                                if let author = parser.getArray(forKey: "author", messageDictionary: data)[offset] {
                                    Text((author as? String ?? "").dropLast(5))
                                        .fontWeight(.semibold)
                                }
                            }
                            Text(content)
                        }
                        Spacer()
                        Button(action: {
                            DispatchQueue.main.async {
                                let i = "\(rootURL)/channels/\(channelID)/messages/\(parser.getArray(forKey: "id", messageDictionary: data)[offset])"
                                let index2 = offset
                                data.remove(at: index2)
                                NetworkHandling.shared.requestData(url: i, token: token, json: false, type: .DELETE, bodyObject: [:]) { success, array in }
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    } else {
                        HStack {
                            Image(nsImage: pfps[(parser.getArray(forKey: "user_id", messageDictionary: data)[safe: offset] as! String)] ?? NSImage()).resizable()
                                .frame(maxWidth: 15, maxHeight: 15)
                                .scaledToFit()
                                .padding(.horizontal, 5)
                                .clipShape(Circle())
                            HStack {
                                if let author = parser.getArray(forKey: "author", messageDictionary: data)[offset] {
                                    Text((author as? String ?? "").dropLast(5))
                                        .fontWeight(.bold)
                                }
                            }

                            Text(content)
                            Spacer()
                            Button(action: {
                                DispatchQueue.main.async {
                                    let i = "\(rootURL)/channels/\(channelID)/messages/\(parser.getArray(forKey: "id", messageDictionary: data)[offset])"
                                    let index2 = offset
                                    data.remove(at: index2)
                                    NetworkHandling.shared.requestData(url: i, token: token, json: false, type: .DELETE, bodyObject: [:]) {success, array in }
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(BorderlessButtonStyle())

                        }
                    }
                }
                if let attachment = parser.getArray(forKey: "attachments", messageDictionary: data)[offset] as? [[String:Any]] {
                    if attachment.isEmpty == false {
                        HStack {
                            ForEach(0..<attachment.count, id: \.self) { index in
                                Attachment(attachment[index]["url"] as! String)
                                    .frame(maxWidth: 400, maxHeight: 300)
                            }
                        }
                        .padding()
                    }
                }
            }
            .rotationEffect(.radians(.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
        }
    }
}

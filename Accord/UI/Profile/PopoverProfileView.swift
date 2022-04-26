//
//  PopoverProfileView.swift
//  Accord
//
//  Created by evelyn on 2021-07-13.
//

import SwiftUI

struct PopoverProfileView: View {
    var user: User?
    @State var hovered: Int?
    
    struct PopoverProfileViewButton: View {
        
        var label: String
        var symbolName: String
        @State var hovered: Int? = nil
        var action: (() -> Void)
        
        var body: some View {
            Button(action: action, label: {
                VStack {
                    Image(systemName: symbolName)
                        .imageScale(.medium)
                    Text(label)
                        .font(.subheadline)
                }
                .padding(4)
                .frame(width: 60, height: 45)
                .background(hovered == 1 ? Color.gray.opacity(0.25).cornerRadius(5) : Color.clear.cornerRadius(5))
            })
            .buttonStyle(BorderlessButtonStyle())
            .onHover(perform: { hover in
                switch hover {
                case true:
                    withAnimation {
                        hovered = 1
                    }
                case false:
                    withAnimation {
                        hovered = nil
                    }
                }
            })
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                if let banner = user?.banner, let id = user?.id {
                    Attachment(cdnURL + "/banners/\(id)/\(banner).png")
                        .equatable()
                        .frame(height: 100)
                } else {
                    Color(NSColor.windowBackgroundColor).frame(height: 100).opacity(0.75)
                }
                Spacer()
            }
            VStack {
                Spacer().frame(height: 100)
                VStack(alignment: .leading) {
                    if user?.avatar?.prefix(2) == "a_" {
                        GifView(url: cdnURL + "/avatars/\(user?.id ?? "")/\(user?.avatar ?? "").gif?size=64")
                            .clipShape(Circle())
                            .frame(width: 45, height: 45)
                            .shadow(radius: 5)
                    } else {
                        Attachment(pfpURL(user?.id, user?.avatar, discriminator: user?.discriminator ?? "0005"))
                            .equatable()
                            .clipShape(Circle())
                            .frame(width: 45, height: 45)
                            .shadow(radius: 5)
                    }
                    Text(user?.username ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(user?.username ?? "")#\(user?.discriminator ?? "")")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                    HStack(alignment: .bottom) {
                        PopoverProfileViewButton(
                            label: "Message",
                            symbolName: "bubble.right.fill"
                        ) {
                            print("lol creating new channel now")
                            Request.fetch(Channel.self, url: URL(string: "https://discord.com/api/v9/users/@me/channels"), headers: Headers(
                                userAgent: discordUserAgent,
                                token: AccordCoreVars.token,
                                bodyObject: ["recipients":[user?.id ?? ""]],
                                type: .POST,
                                discordHeaders: true,
                                referer: "https://discord.com/channels/@me",
                                json: true
                            )) {
                                switch $0 {
                                case .success(let channel):
                                    print(channel)
                                    ServerListView.privateChannels.append(channel)
                                    MentionSender.shared.select(channel: channel)
                                case .failure(let error):
                                    AccordApp.error(error, text: "Failed to open dm", reconnectOption: false)
                                }
                            }
                        }
                        PopoverProfileViewButton(
                            label: "Call",
                            symbolName: "phone.fill"
                        ) {
                            // todo: voice chat
                        }
                        PopoverProfileViewButton(
                            label: "Video call",
                            symbolName: "camera.circle.fill"
                        ) {
                            // todo: video call
                        }
                        PopoverProfileViewButton(
                            label: "Add Friend",
                            symbolName: "person.crop.circle.badge.plus"
                        ) {
                            // todo: check add friend
                        }
                    }
                    .transition(AnyTransition.opacity)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(width: 290, height: 250)
    }
}

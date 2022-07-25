//
//  PopoverProfileView.swift
//  Accord
//
//  Created by evelyn on 2021-07-13.
//

import SwiftUI

// thanks to https://stackoverflow.com/questions/62102647/swiftui-hstack-with-wrap-and-dynamic-height/62103264#62103264
struct RolesView: View {
    var tags: [String]

    @State private var totalHeight = Double.infinity

    var body: some View {
        self.generateContent().frame(maxHeight: totalHeight)
    }

    private func generateContent() -> some View {
        var width = Double.zero
        var height = Double.zero

        return ZStack(alignment: .topLeading) {
            ForEach(self.tags, id: \.self) { tag in
                self.item(for: tag)
                    .alignmentGuide(.leading, computeValue: { d in
                        if abs(width - d.width) > 262 {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if tag == self.tags.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if tag == self.tags.last {
                            height = 0
                        }
                        return result
                    })
            }
        }.background(viewHeightReader($totalHeight))
    }

    @ViewBuilder
    private func item(for role: String) -> some View {
        if let roleName = Storage.roleNames[role] {
            HStack(spacing: 4) {
                if #available(macOS 13.0, *) {
                    Circle()
                        .fill(color(for: role).gradient)
                        .frame(width: 10, height: 10)
                } else {
                    Circle()
                        .fill(color(for: role))
                        .frame(width: 10, height: 10)
                }
                Text(roleName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)
            .padding(4)
        }
    }

    func color(for role: String) -> Color {
        if let roleColor = Storage.roleColors[role]?.0 {
            return Color(int: roleColor)
        }
        return Color.secondary
    }

    private func viewHeightReader(_ binding: Binding<Double>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

struct PopoverProfileView: View {
    @State var user: User?
    
    @Environment(\.guildID)
    var guildID: String
    
    @State var guildMember: GuildMember? = nil
    @State var fullUser: User? = nil
    @State var hovered: Int?

    struct PopoverProfileViewButton: View {
        var label: String
        var symbolName: String
        @State var hovered: Int? = nil
        var action: () -> Void

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

    var userObject: User?

    final class UserRequest: Decodable {
        var user: User
        var guild_member: GuildMember?
    }

    func loadUser() {
        let url = URL(string: rootURL)?
            .appendingPathComponent("users")
            .appendingPathComponent(user?.id ?? "")
            .appendingPathComponent("profile")
            .appendingQueryParameters(
                guildID == "@me" ?
                    ["with_mutual_guilds": "false"] :
                    ["with_mutual_guilds": "false", "guild_id": guildID]
            )
        Request.fetch(UserRequest.self, url: url, headers: standardHeaders) {
            switch $0 {
            case let .success(user):
                DispatchQueue.main.async {
                    self.fullUser = user.user
                    self.guildMember = user.guild_member
                }
            case let .failure(error):
                print(error)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                if let banner = fullUser?.banner, let id = user?.id {
                    Attachment(cdnURL + "/banners/\(id)/\(banner).png?size=320")
                        .equatable()
                        .scaledToFit()
                        .frame(width: 290)
                } else {
                    Color(NSColor.windowBackgroundColor).frame(height: 100).opacity(0.75)
                }
                Spacer()
            }
            VStack {
                Spacer().frame(height: 100)
                VStack(alignment: .leading) {
                    if user?.avatar?.prefix(2) == "a_" {
                        ZStack(alignment: .center) {
                            Circle().frame(width: 64, height: 64)
                                .foregroundColor(Color(NSColor.windowBackgroundColor))
                            GifView(cdnURL + "/avatars/\(user?.id ?? "")/\(user?.avatar ?? "").gif?size=64")
                                .clipShape(Circle())
                                .frame(width: 60, height: 60)
                        }
                        .offset(y: -48)
                        .padding(.bottom, -48)
                    } else {
                        ZStack(alignment: .center) {
                            Circle().frame(width: 64, height: 64)
                                .foregroundColor(Color(NSColor.windowBackgroundColor))
                            Attachment(pfpURL(user?.id, user?.avatar, discriminator: user?.discriminator ?? "0005"))
                                .equatable()
                                .clipShape(Circle())
                                .frame(width: 60, height: 60)
                        }
                        .offset(y: -48)
                        .padding(.bottom, -48)
                    }
                    Text(self.guildMember?.nick ?? user?.username ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(user?.username ?? "")#\(user?.discriminator ?? "")")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)

                    if let bio = self.fullUser?.bio, !bio.isEmpty {
                        Divider()
                        Text("About me")
                            .fontWeight(.semibold)
                            .padding(.bottom, 1)
                        AsyncMarkdown(bio)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider()
                    }
                    if let roles = self.guildMember?.roles?.sorted(by: { lhs, rhs in
                        if let lhs = Storage.roleColors[lhs]?.1, let rhs = Storage.roleColors[rhs]?.1 {
                            return lhs > rhs
                        } else { return true }
                    }) {
                        RolesView(tags: roles)
                    }
                    Divider()
                    Button(action: {
                        Request.fetch(Channel.self, url: URL(string: "https://discord.com/api/v9/users/@me/channels"), headers: Headers(
                            token: Globals.token,
                            bodyObject: ["recipients": [user?.id ?? ""]],
                            type: .POST,
                            discordHeaders: true,
                            referer: "https://discord.com/channels/@me",
                            json: true
                        )) {
                            switch $0 {
                            case let .success(channel):
                                print(channel)
                                AppGlobals.newItemPublisher.send((channel, nil))
                                MentionSender.shared.select(channel: channel)
                            case let .failure(error):
                                AccordApp.error(error, text: "Failed to open dm", reconnectOption: false)
                            }
                        }
                    }) {
                        HStack {
                            Text("Message")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .transition(AnyTransition.opacity)
                }
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(width: 290)
        .onAppear {
            DispatchQueue.global().async {
                self.loadUser()
            }
        }
    }
}

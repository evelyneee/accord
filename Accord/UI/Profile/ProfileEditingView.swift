//
//  ProfileEditingView.swift
//  Accord
//
//  Created by evelyn on 2022-05-14.
//

import SwiftUI

extension NSTextView {
    override open var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }
    }
}

struct ProfileEditingView: View {
    @State var username: String = ""
    @State var status: String = ""
    @State var bioText: String = ""
    @State var user = Globals.user
    @State var filePicker = false
    @State var bannerPicker = false
    @State var imageData: Data? = nil
    @State var bannerData: Data? = nil
    @State var emotePopup: Bool = false
    @State var emoteID: String? = nil
    @State var emoteName: String? = nil
    @State var emoteAnimated: Bool? = nil

    @Environment(\.colorScheme) var colorScheme

    func updateProfile(settings: Bool = false, _ dict: [String: Any]) {
        DispatchQueue.global().async {
            var url = URL(string: rootURL)?
                .appendingPathComponent("users")
                .appendingPathComponent("@me")
            if settings {
                url = url?.appendingPathComponent("settings")
            }
            Request.fetch(User.self, url: url, headers: Headers(
                token: Globals.token,
                bodyObject: dict,
                type: .PATCH,
                discordHeaders: true,
                referer: "https://discord.com/channels/@me",
                json: true
            )) {
                switch $0 {
                case let .success(user):
                    Globals.user = user
                    DispatchQueue.main.async {
                        self.user = user
                        if let bio = user.bio {
                            self.bioText = bio
                        }
                    }
                case let .failure(error):
                    print(error)
                }
            }
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Username")
                    .font(.title3)
                    .fontWeight(.semibold)
                TextField("Type in your username", text: self.$username)
                    .textFieldStyle(.roundedBorder)
                Text("Status")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 5)
                HStack {
                    Button(action: {
                        self.emotePopup.toggle()
                    }, label: {
                        if let emoteID = emoteID {
                            Attachment(cdnURL + "/emojis/\(emoteID).png?size=48")
                                .frame(width: 16, height: 16)
                        } else if let emoteName = emoteName {
                            Text(emoteName)
                        } else if let emoji = Activity.current?.emoji {
                            if let id = emoji.id {
                                Attachment(cdnURL + "/emojis/\(id).png?size=48")
                                    .frame(width: 16, height: 16)
                            } else if let name = emoji.name {
                                Text(name)
                            }
                        } else {
                            Image(systemName: "face.smiling.fill")
                        }
                    })
                    .buttonStyle(.borderless)
                    .popover(isPresented: self.$emotePopup, content: {
                        EmotesView(onSelect: { emote in
                            if emote.id == "stock" {
                                self.emoteName = emote.name
                                self.emoteID = nil
                                return
                            }
                            self.emoteID = emote.id
                            self.emoteName = emote.name
                            self.emoteAnimated = emote.animated
                            self.emotePopup = false
                        })
                    })
                    TextField("Type in your status", text: self.$status)
                        .textFieldStyle(.roundedBorder)
                    if self.status != Activity.current?.state || self.emoteID != Activity.current?.emoji?.id {
                        Button("Save") {
                            Activity.current?.state = self.status
                            if let emoteID = emoteID, let emoteName = emoteName, let emoteAnimated = emoteAnimated {
                                Activity.current?.emoji = StatusEmoji(name: emoteName, id: emoteID, animated: emoteAnimated)
                                wss.presences[0] = Activity.current!
                                try? wss.updatePresence(status: MediaRemoteWrapper.status ?? "online", since: 0, activities: wss.presences)
                                if self.status.isEmpty {
                                    updateProfile(settings: true, ["custom_status": [
                                        "emoji_id": self.emoteID,
                                        "emoji_name": self.emoteName,
                                    ]])
                                } else {
                                    updateProfile(settings: true, ["custom_status": [
                                        "text": self.status,
                                        "emoji_id": self.emoteID,
                                        "emoji_name": self.emoteName,
                                    ]])
                                }
                            } else if let emoteName = emoteName {
                                Activity.current?.emoji = StatusEmoji(name: emoteName, id: nil, animated: nil)
                                wss.presences[0] = Activity.current!
                                try? wss.updatePresence(status: MediaRemoteWrapper.status ?? "online", since: 0, activities: wss.presences)
                                if self.status.isEmpty {
                                    updateProfile(settings: true, ["custom_status": [
                                        "emoji_name": emoteName
                                    ]])
                                } else {
                                    updateProfile(settings: true, ["custom_status": [
                                        "text": self.status,
                                        "emoji_name": emoteName
                                    ]])
                                }
                            } else if !self.status.isEmpty {
                                Activity.current?.state = self.status
                                wss.presences[0] = Activity.current!
                                try? wss.updatePresence(status: MediaRemoteWrapper.status ?? "online", since: 0, activities: wss.presences)
                                updateProfile(settings: true, ["custom_status": [
                                    "text": self.status,
                                ]])
                            } else {
                                Activity.current?.state = nil
                                wss.presences[0] = Activity.current!
                                try? wss.updatePresence(status: MediaRemoteWrapper.status ?? "online", since: 0, activities: wss.presences)
                                updateProfile(settings: true, ["custom_status": []])
                            }
                        }
                    }
                }
                Text("Bio")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 5)
                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: self.$bioText)
                        .font(.body)
                        .frame(height: 50)
                        .padding(5)
                        .background(self.colorScheme == .dark ? Color(red: 0.23, green: 0.21, blue: 0.21) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    if self.user?.bio != self.bioText {
                        Button("Save") {
                            updateProfile(["bio": self.bioText])
                        }
                        .padding(5)
                    }
                }
            }
            .padding()
            VStack {
                ZStack(alignment: .bottomTrailing) {
                    Button(action: {
                        self.bannerPicker.toggle()
                    }, label: {
                        if let bannerData = bannerData,
                           let image = NSImage(data: bannerData)
                        {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 290)
                        } else if let banner = self.user?.banner, let id = self.user?.id {
                            Attachment(cdnURL + "/banners/\(id)/\(banner).png?size=320")
                                .equatable()
                                .scaledToFit()
                                .frame(width: 290)
                        } else {
                            Color(NSColor.windowBackgroundColor).frame(height: 100).opacity(0.75)
                        }
                    })
                    .buttonStyle(.plain)
                    .fileImporter(isPresented: self.$bannerPicker, allowedContentTypes: [.image]) { result in
                        guard let result = try? result.get(),
                              let data = try? Data(contentsOf: result) else { return }
                        self.bannerData = data
                    }
                    if let bannerData = bannerData {
                        Button("Save") {
                            updateProfile(["banner": "data:image/png;base64," + bannerData.base64EncodedString()])
                            self.bannerData = nil
                        }
                        .padding(3)
                    }
                }
                VStack(alignment: .leading) {
                    Button(action: {
                        self.filePicker.toggle()
                    }, label: {
                        if let imageData = imageData,
                           let image = NSImage(data: imageData)
                        {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: 45, height: 45)
                            Button("Save") {
                                updateProfile(["avatar": "data:image/png;base64," + imageData.base64EncodedString()])
                                self.imageData = nil
                            }
                        } else if self.user?.avatar?.prefix(2) == "a_" {
                            GifView(cdnURL + "/avatars/\(self.user?.id ?? "")/\(self.user?.avatar ?? "").gif?size=64")
                                .clipShape(Circle())
                                .frame(width: 45, height: 45)
                        } else if let userID = self.user?.id, let avatar = self.user?.avatar {
                            Attachment(pfpURL(userID, avatar, discriminator: self.user?.discriminator ?? "0005"))
                                .clipShape(Circle())
                                .frame(width: 45, height: 45)
                        }
                    })
                    .buttonStyle(.plain)
                    .fileImporter(isPresented: self.$filePicker, allowedContentTypes: [.image]) { result in
                        guard let result = try? result.get(),
                              let data = try? Data(contentsOf: result) else { return }
                        self.imageData = data
                    }
                    Text(self.user?.username ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(self.user?.username ?? "")#\(self.user?.discriminator ?? "")")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                    Divider()
                    Text("About me")
                        .fontWeight(.semibold)
                        .padding(.bottom, 1)
                    AsyncMarkdown(self.bioText, binded: self.$bioText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding([.horizontal, .bottom])
                .frame(width: 290)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            .padding()
        }
        .onAppear {
            if Globals.user?.bio == nil {
                self.loadUser()
            } else {
                self.user = Globals.user
                dump(self.user)
                self.bioText = Globals.user?.bio ?? ""
                self.username = Globals.user?.username ?? ""
                self.status = Activity.current?.state ?? ""
            }
        }
    }

    func loadUser() {
        let url = URL(string: rootURL)?
            .appendingPathComponent("users")
            .appendingPathComponent("@me")
            .appendingPathComponent("profile")
            .appendingQueryParameters(
                ["with_mutual_guilds": "false"]
            )
        Request.fetch(PopoverProfileView.UserRequest.self, url: url, headers: standardHeaders) {
            switch $0 {
            case let .success(user):
                print(user)
                DispatchQueue.main.async {
                    Globals.user = user.user
                    self.user = user.user
                }
            case let .failure(error):
                print(error)
            }
        }
    }
}

struct ProfileEditingView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileEditingView()
    }
}

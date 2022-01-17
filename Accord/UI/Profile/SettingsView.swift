//
//  SettingsViewRedesign.swift
//  Accord
//
//  Created by evewyn on 2021-07-14.
//

import Foundation
import SwiftUI

@available(macOS 11.0, *)
struct SettingsViewRedesign: View {

    @AppStorage("pfpShown") var profilePictures: Bool = pfpShown
    @AppStorage("sortByMostRecent") var recent: Bool = sortByMostRecent
    @AppStorage("darkMode") var dark: Bool = darkMode
    @AppStorage("proxyIP") var proxyIP: String = ""
    @AppStorage("proxyPort") var proxyPort: String = ""
    @AppStorage("proxyEnabled") var proxyEnable: Bool = proxyEnabled
    @AppStorage("pastelColors") var pastel: Bool = pastelColors
    @AppStorage("discordStockSettings") var discordSettings: Bool = pastelColors
    @AppStorage("enableSuffixRemover") var suffixes: Bool = false
    @AppStorage("pronounDB") var pronounDB: Bool = false
    @AppStorage("AppleMusicRPC") var appleMusicRPC: Bool = false
    @AppStorage("XcodeRPC") var xcodeRPC: Bool = false
    @AppStorage("DiscordDesktopRPCEnabled") var ddRPC: Bool = false
    @AppStorage("VSCodeRPCEnabled") var vsRPC: Bool = false

    @State var user: User? = AccordCoreVars.user
    @State var selectedPlatform: Platforms = musicPlatform ?? Platforms.appleMusic
    @State var loading: Bool = false
    @State var bioText: String = " "
    @State var username: String = AccordCoreVars.user?.username ?? "Unknown User"
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            LazyVStack(alignment: .leading) {
                Text("Accord Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 20)
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("Email")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(user?.email ?? "No email found")
                        }
                        .padding(.bottom, 10)
                        VStack(alignment: .leading) {
                            Text("Phone number")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("not done yet, placeholder")
                        }
                        .padding(.bottom, 10)
                        Spacer()
                    }
                    .padding()
                    Divider()
                    VStack(alignment: .leading) {
                        Text("Bio")
                            .font(.title3)
                            .fontWeight(.bold)
                        TextEditor(text: $bioText)
                            .frame(height: 75)
                        Text("Username")
                            .font(.title3)
                            .fontWeight(.bold)
                        TextField("username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Spacer()
                    }
                    .frame(idealWidth: 250, idealHeight: 200)
                    .padding()
                    Divider()
                    VStack(alignment: .leading) {
                        Attachment("https://cdn.discordapp.com/avatars/\(user?.id ?? "")/\(user?.avatar ?? "").png")
                            .clipShape(Circle())
                            .frame(width: 45, height: 45)
                            .shadow(radius: 5)
                        Text(user?.username ?? "Unknown User")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(user?.username ?? "Unknown User")#\(user?.discriminator ?? "0000")")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                        Divider()
                        Text(bioText)
                        Spacer()
                    }
                    .frame(idealWidth: 200, idealHeight: 200)
                    .padding()
                    Spacer()
                }
                .padding(5)
                .background(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10))
                .cornerRadius(15)
                .padding()
                .disabled(true)
                VSplitView {
                    SettingsToggleView(toggled: $profilePictures, title: "Show profile pictures")
                        .disabled(true)
                    SettingsToggleView(toggled: $discordSettings, title: "Use stock discord settings")
                        .disabled(true)
                    SettingsToggleView(toggled: $recent, title: "Sort servers by recent messages")
                        .disabled(true)
                    SettingsToggleView(toggled: $suffixes, title: "Enable useless suffix remover")
                        .disabled(true)
                    SettingsToggleView(toggled: $pronounDB, title: "Enable PronounDB integration")
                    SettingsToggleView(toggled: $dark, title: "Always dark mode")
                    HStack(alignment: .top) {
                        Text("Music platform")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Picker(selection: $selectedPlatform, content: {
                            Text("Amazon Music").tag(Platforms.amazonMusic)
                            Text("Apple Music").tag(Platforms.appleMusic)
                            Text("Deezer").tag(Platforms.deezer)
                            Text("iTunes").tag(Platforms.itunes)
                            Text("Napster").tag(Platforms.napster)
                            Text("Pandora").tag(Platforms.pandora)
                            Text("Soundcloud").tag(Platforms.soundcloud)
                            Text("Spotify").tag(Platforms.spotify)
                            Text("Tidal").tag(Platforms.tidal)
                            Text("Youtube Music").tag(Platforms.youtubeMusic)
                        }, label: {
                        })
                        .padding()
                    }
                    .disabled(true)
                    Group {
                        SettingsToggleView(toggled: $xcodeRPC, title: "Enable Xcode Rich Presence")
                        SettingsToggleView(toggled: $appleMusicRPC, title: "Enable Apple Music Rich Presence")
                        SettingsToggleView(toggled: $ddRPC, title: "Enable Discord Client Rich Presence")
                        SettingsToggleView(toggled: $vsRPC, title: "Enable Visual Studio Code Rich Presence", detail: "This requires the screen recording permission")
                    }
                }
                .toggleStyle(SwitchToggleStyle())
                .pickerStyle(MenuPickerStyle())
                .padding(5)
                .background(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10))
                .cornerRadius(15)
                .padding()
                Text("Proxy Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 20)
                VSplitView {
                    SettingsToggleView(toggled: $proxyEnable, title: "Enable Proxy")
                        .toggleStyle(SwitchToggleStyle())
                    HStack(alignment: .top) {
                        Text("Proxy Config")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        HStack {
                            TextField("IP", text: $proxyIP)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                            Text(":")
                            TextField("Port", text: $proxyPort)
                                .frame(width: 50)
                        }
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Load plugin")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Button("Load") {
                            self.loading.toggle()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .padding()
                    }
                    .fileImporter(isPresented: $loading, allowedContentTypes: [.data], onCompletion: { result in
                        do {
                            let url = try result.get()
                            let path = FileManager.default.urls(for: .documentDirectory,
                                                                   in: .userDomainMask)[0].appendingPathComponent(UUID().uuidString)
                            if FileManager.default.secureCopyItem(at: url, to: path) {
                                print("Plugin successfully copied")
                            }
                        } catch {

                        }
                    })
                }
                .padding(5)
                .background(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10))
                .cornerRadius(15)
                .padding()
                .disabled(true)
                Text("Accord (red.evelyn.accord) \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                    .padding(.leading, 20)
                    .foregroundColor(.secondary)
                Text("OS: macOS \(String(describing: ProcessInfo.processInfo.operatingSystemVersionString))")
                    .padding(.leading, 20)
                    .foregroundColor(.secondary)
                HStack(alignment: .center) {
                    Text("Open source at")
                        .padding(.leading, 20)
                        .foregroundColor(.secondary)
                    GithubIcon()
                        .foregroundColor(Color.accentColor)
                        .frame(width: 13, height: 13)
                        .onTapGesture {
                            NSWorkspace.shared.open(URL(string: "https://github.com/evelyneee/Accord")!)
                        }
                }
                .frame(height: 5)
                Text("Made with 🤍 by Evelyn")
                    .padding(.leading, 20)
                    .foregroundColor(.secondary)
            }
            .onDisappear {
                darkMode = dark
                sortByMostRecent = recent
                pfpShown = profilePictures
                pastelColors = pastel
                discordStockSettings = discordSettings
            }
        }
    }
}

extension FileManager {

    open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch let error {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }

}

struct SettingsToggleView: View {
    @Binding var toggled: Bool
    var title: String
    var detail: String? = nil
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                if let detail = detail {
                    Text(detail)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            Spacer()
            Toggle(isOn: $toggled) {
            }
            .padding()
        }
    }
}

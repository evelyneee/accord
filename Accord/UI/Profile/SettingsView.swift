//
//  SettingsViewRedesign.swift
//  Accord
//
//  Created by evewyn on 2021-07-14.
//

import Foundation
import SwiftUI

@available(macOS 11.0, *)
struct SettingsView: View {
    @AppStorage("pfpShown")
    var profilePictures: Bool = pfpShown
    @AppStorage("sortByMostRecent")
    var recent: Bool = sortByMostRecent
    @AppStorage("darkMode")
    var dark: Bool = darkMode
    @AppStorage("proxyIP")
    var proxyIP: String = ""
    @AppStorage("proxyPort")
    var proxyPort: String = ""
    @AppStorage("proxyEnabled")
    var proxyEnable: Bool = proxyEnabled
    @AppStorage("pastelColors")
    var pastel: Bool = pastelColors
    @AppStorage("discordStockSettings")
    var discordSettings: Bool = pastelColors
    @AppStorage("enableSuffixRemover")
    var suffixes: Bool = false
    @AppStorage("pronounDB")
    var pronounDB: Bool = false
    @AppStorage("AppleMusicRPC")
    var appleMusicRPC: Bool = false
    @AppStorage("SpotifyRPC")
    var spotifyRPC: Bool = true
    @AppStorage("XcodeRPC")
    var xcodeRPC: Bool = false
    @AppStorage("DiscordDesktopRPCEnabled")
    var ddRPC: Bool = false
    @AppStorage("VSCodeRPCEnabled")
    var vsRPC: Bool = false
    @AppStorage("MentionsMenuBarItemEnabled")
    var menuBarItem: Bool = false
    @AppStorage("MetalRenderer")
    var metalRenderer: Bool = false
    @AppStorage("Nitroless")
    var nitrolessEnabled: Bool = false
    @AppStorage("SilentTyping")
    var silentTyping: Bool = false
    @AppStorage("GifProfilePictures")
    var gifPfp: Bool = false
    @AppStorage("ShowHiddenChannels")
    var showHiddenChannels: Bool = false
    @AppStorage("MusicPlatform")
    var selectedPlatform: String = "appleMusic"
    @AppStorage("CompressGateway")
    var compress: Bool = false

    @State var user: User? = AccordCoreVars.user
    @State var loading: Bool = false
    @State var bioText: String = " "
    @State var username: String = AccordCoreVars.user?.username ?? "Unknown User"
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            LazyVStack(alignment: .leading) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 20)
                #if false
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
                            Text("MFA enabled")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(user?.mfa_enabled ?? false ? "Yes" : "No")
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
                        Attachment(cdnURL + "/avatars/\(user?.id ?? "")/\(user?.avatar ?? "").png")
                            .equatable()
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
                #endif
                VSplitView {
                    Group {
                        SettingsToggleView(toggled: $profilePictures, title: "Show profile pictures")
                        SettingsToggleView(toggled: $discordSettings, title: "Use stock discord settings")
                        SettingsToggleView(toggled: $recent, title: "Sort servers by recent messages")
                        SettingsToggleView(toggled: $suffixes, title: "Enable useless suffix remover")
                    }
                    .disabled(true)
                    Group {
                        SettingsToggleView(toggled: $pronounDB, title: "Enable PronounDB integration")
                        SettingsToggleView(toggled: $dark, title: "Always dark mode")
                        SettingsToggleView(toggled: $menuBarItem, title: "Enable the mentions menu bar popup")
                        SettingsToggleView(toggled: $nitrolessEnabled, title: "Enable Nitroless support")
                        SettingsToggleView(toggled: $silentTyping, title: "Enable silent typing")
                        SettingsToggleView(toggled: $metalRenderer, title: "Enable the Metal Renderer for the chat view", detail: "Experimental")
                        SettingsToggleView(toggled: $gifPfp, title: "Enable Gif Profile Pictures", detail: "Experimental")
                        SettingsToggleView(toggled: $showHiddenChannels, title: "Show hidden channels", detail: "Please don't use this")
                        SettingsToggleView(toggled: $compress, title: "Enable Gateway Stream Compression", detail: "Recommended")
                    }

                    HStack(alignment: .top) {
                        Text("Music platform")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Menu("Select your platform") {
                            Button("Amazon Music", action: { self.selectedPlatform = Platforms.amazonMusic.rawValue })
                            Button("Apple Music", action: { self.selectedPlatform = Platforms.appleMusic.rawValue })
                            Button("Deezer", action: { self.selectedPlatform = Platforms.deezer.rawValue })
                            Button("iTunes", action: { self.selectedPlatform = Platforms.itunes.rawValue })
                            Button("Napster", action: { self.selectedPlatform = Platforms.napster.rawValue })
                            Button("Pandora", action: { self.selectedPlatform = Platforms.pandora.rawValue })
                            Button("Soundcloud", action: { self.selectedPlatform = Platforms.soundcloud.rawValue })
                            Button("Spotify", action: { self.selectedPlatform = Platforms.spotify.rawValue })
                            Button("Tidal", action: { self.selectedPlatform = Platforms.tidal.rawValue })
                            Button("Youtube Music", action: { self.selectedPlatform = Platforms.youtubeMusic.rawValue })
                        }
                        .padding()
                    }
                    Group {
                        SettingsToggleView(toggled: $xcodeRPC, title: "Enable Xcode Rich Presence")
                        SettingsToggleView(toggled: $appleMusicRPC, title: "Enable Apple Music Rich Presence")
                        SettingsToggleView(toggled: $spotifyRPC, title: "Enable Spotify Rich Presence in Apple Music", detail: "This will show your currently playing Apple Music song in Spotify Presence")
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
                #if false
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
                        } catch {}
                    })
                }
                .padding(5)
                .background(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10))
                .cornerRadius(15)
                .padding()
                .disabled(true)
                #endif
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
                // discordStockSettings = discordSettings
            }
            .toolbar {
                ToolbarItemGroup {
                    Toggle(isOn: Binding.constant(false)) {
                        Image(systemName: "bell.badge.fill")
                    }
                    .hidden()
                }
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
        } catch {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }
}

struct SettingsToggleView: View {
    @Binding var toggled: Bool
    var title: String
    var detail: String?
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
            Toggle(isOn: $toggled) {}
                .padding()
        }
    }
}

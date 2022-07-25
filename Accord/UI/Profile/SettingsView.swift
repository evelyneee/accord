//
//  SettingsViewRedesign.swift
//  Accord
//
//  Created by evewyn on 2021-07-14.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @AppStorage("MusicPlatform")
    var selectedPlatform: String = "appleMusic"

    @State var user: User? = Globals.user
    @State var loading: Bool = false
    @State var bioText: String = " "
    @State var username: String = Globals.user?.username ?? "Unknown User"
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            LazyVStack(alignment: .leading) {
                VSplitView {
                    Group {
                        SettingsToggleView(key: "pfpShown", title: "Show profile pictures")
                        SettingsToggleView(key: "discordStockSettings", title: "Use stock discord settings")
                        SettingsToggleView(key: "sortByMostRecent", title: "Sort servers by recent messages")
                        SettingsToggleView(key: "enableSuffixRemover", title: "Enable useless suffix remover")
                    }
                    .disabled(true)
                    Group {
                        SettingsToggleView(key: "pronounDB", title: "Enable PronounDB integration")
                        SettingsToggleView(key: "darkMode", title: "Always dark mode")
                        SettingsToggleView(key: "MentionsMenuBarItemEnabled", title: "Enable the mentions menu bar popup")
                        SettingsToggleView(key: "Nitroless", title: "Enable Nitroless support")
                        SettingsToggleView(key: "SilentTyping", title: "Enable silent typing")
                        SettingsToggleView(key: "MetalRenderer", title: "Enable the Metal Renderer for the chat view", detail: "Experimental")
                        SettingsToggleView(key: "GifProfilePictures", title: "Enable Gif Profile Pictures", detail: "Experimental")
                        SettingsToggleView(key: "ShowHiddenChannels", title: "Show hidden channels", detail: "Please don't use this")
                        SettingsToggleView(key: "CompressGateway", title: "Enable Gateway Stream Compression", detail: "Recommended", defaultToggle: true)
                        SettingsToggleView(key: "Highlighting", title: "Use dark blockchain technology", detail: "Ask around for what this does!")
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
                        SettingsToggleView(key: "XcodeRPC", title: "Enable Xcode Rich Presence")
                        SettingsToggleView(key: "AppleMusicRPC", title: "Enable Apple Music Rich Presence")
                        SettingsToggleView(key: "SpotifyRPC", title: "Enable Spotify Rich Presence in Apple Music", detail: "This will show your currently playing Apple Music song in Spotify Presence")
                        SettingsToggleView(key: "VSCodeRPCEnabled", title: "Enable Visual Studio Code Rich Presence", detail: "This requires the screen recording permission")
                    }
                }
                .toggleStyle(SwitchToggleStyle())
                .pickerStyle(MenuPickerStyle())
                .padding(5)
                .background(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10))
                .cornerRadius(15)
                .padding()
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

public extension FileManager {
    func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
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
    var key: String
    var title: String
    var detail: String?
    var defaultToggle: Bool?
    @State var toggled: Bool = false
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
                .onChange(of: self.toggled, perform: { _ in
                    UserDefaults.standard.set(self.toggled, forKey: key)
                })
                .padding()
                .onAppear {
                    self.toggled = UserDefaults.standard.object(forKey: self.key) as? Bool ?? defaultToggle ?? false
                }
        }
    }
}

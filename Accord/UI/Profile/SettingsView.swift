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
    var selectedPlatform: Platforms = .appleMusic
    @AppStorage("CompressGateway")
    var compress: Bool = false
    @State var useGenericRPC: Bool = false
    
    @State var user: User? = AccordCoreVars.user
    @State var loading: Bool = false
    @State var bioText: String = " "
    @State var username: String = AccordCoreVars.user?.username ?? "Unknown User"
    @State var selectedApp: NSRunningApplication = .current
    @State var genericRPCDetails: String = ""
    @State var rpcIconURL: String = ""
    var availableApps: [NSRunningApplication] {
        // we need to filer out by normal apps, otherwise this would be bloated with several background processes
        NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
    }
    
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
                        }, label: {})
                            .padding()
                    }
                    .disabled(true)
                }
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
                }
                .padding(5)
                .background(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10))
                .cornerRadius(15)
                .padding()
                .disabled(true)
                Text("Rich Presence Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 20)
                VSplitView {
                    SettingsToggleView(toggled: $useGenericRPC, title: "Enable Rich Presence", detail: "Enables rich presence and allows you to choose what app to display")
                        .onChange(of: useGenericRPC) { _ in
                            callAppRPC()
                        }
                    HStack(alignment: .top) {
                        Text("Enable Rich Presence for..")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Picker(selection: $selectedApp, content: {
                            ForEach(availableApps, id: \.self) { app in
                                if let name = app.localizedName {
                                    Text(name)
                                }
                            }
                        }, label: {})
                            .padding()
                            .onChange(of: selectedApp) { _ in
                                callAppRPC()
                            }
                    }
                    .disabled(!useGenericRPC)

                    RPCInfoTextFields
                    
                    SettingsToggleView(toggled: $xcodeRPC, title: "Enable Xcode Rich Presence", detail: "Will display the current file being edited")
                    SettingsToggleView(toggled: $appleMusicRPC, title: "Enable Apple Music Rich Presence", detail: "This will display the current Song you're listening to")
                    SettingsToggleView(toggled: $ddRPC, title: "Enable Discord Client Rich Presence", detail: "This will display the current channel you're talking in")
                    SettingsToggleView(toggled: $vsRPC, title: "Enable Visual Studio Code Rich Presence", detail: "This requires the screen recording permission")
                }
                .padding(5)
                .background(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10))
                .cornerRadius(15)
                .padding()
                
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
    }
    
    
    @ViewBuilder var RPCInfoTextFields: some View {
        HStack(alignment: .top) {
            Text("Custom RPC Details")
            TextField("", text: $genericRPCDetails)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .disabled(!useGenericRPC)
        
        HStack(alignment: .top) {
            Text("RPC Icon URL")
            TextField("Icon URL", text: $rpcIconURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .disabled(!useGenericRPC)
    }
    
    func callAppRPC() {
        if useGenericRPC {
            let instance = GenericAppPresence(withApp: selectedApp, details: genericRPCDetails.isEmpty ? nil : genericRPCDetails, iconURL: rpcIconURL.isEmpty ? nil : rpcIconURL)
            instance.updatePresence()
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
            .toggleStyle(SwitchToggleStyle())
        }
    }
}

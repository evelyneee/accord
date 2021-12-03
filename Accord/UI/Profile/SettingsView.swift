//
//  SettingsViewRedesign.swift
//  Accord
//
//  Created by evewyn on 2021-07-14.
//

import Foundation
import SwiftUI

// NSViewWrapper(Plugins().loadView(url: "/Users/evelyn/plugin")!.body!)

struct SettingsViewRedesign: View {
    @State var bioText: String = " "
    @State var username: String = "test user"
    @State var profilePictures: Bool = pfpShown
    @State var recent: Bool = sortByMostRecent
    @State var dark: Bool = darkMode
    @State var user: User? = AccordCoreVars.shared.user
    @State var proxyIP: String = ""
    @State var proxyPort: String = ""
    @State var proxyEnable: Bool = proxyEnabled
    @State var pastel: Bool = pastelColors
    @State var discordSettings: Bool = pastelColors
    @State var selectedPlatform: Platforms = musicPlatform ?? Platforms.appleMusic
    @State var loading: Bool = false
    @AppStorage("enableSuffixRemover") var suffixes: Bool = false
    @AppStorage("pronounDB") var pronounDB: Bool = false
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
                        Attachment("https://cdn.discordapp.com/avatars/\(user?.id ?? "")/\(user?.avatar ?? "").png?size=256").equatable()
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
                .background(Color.black.opacity(0.25))
                .cornerRadius(15)
                .padding()
                VSplitView {
                    HStack(alignment: .top) {
                        Text("Show profile pictures")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $profilePictures) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    HStack(alignment: .top) {
                        Text("Use stock discord settings")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $discordSettings) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    HStack(alignment: .top) {
                        Text("Sort servers by recent messages")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $recent) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    HStack(alignment: .top) {
                        Text("Enable useless suffix remover")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $suffixes) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    HStack(alignment: .top) {
                        Text("Enable PronounDB integration")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $pronounDB) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    HStack(alignment: .top) {
                        Text("Always dark mode")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $dark) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
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
                        }, label: {
                        })
                        .padding()
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .padding(5)
                .background(Color.black.opacity(0.25))
                .cornerRadius(15)
                .padding()
                Text("Proxy Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 20)
                VStack {
                    HStack(alignment: .top) {
                        Text("Enable Proxy")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        Toggle(isOn: $proxyEnable) {
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle())
                    }
                    HStack(alignment: .top) {
                        Text("Proxy IP")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        TextField("IP", text: $proxyIP)
                            .padding()
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(width: 250)
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Text("Proxy Port")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                        Spacer()
                        TextField("Port", text: $proxyPort)
                            .padding()
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(width: 250)
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
                .background(Color.black.opacity(0.25))
                .cornerRadius(15)
                .padding()
                Text("Accord (me.evelyn.accord) \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""), using \(String(describing: report_memory())) bytes of RAM")
                    .padding(.leading, 20)
                    .foregroundColor(.secondary)
                Text("OS: macOS \(String(describing: ProcessInfo.processInfo.operatingSystemVersionString))")
                    .padding(.leading, 20)
                    .foregroundColor(.secondary)
            }
            .onDisappear(perform: {
                darkMode = self.dark
                sortByMostRecent = self.recent
                pfpShown = self.profilePictures
                pastelColors = pastel
                discordStockSettings = discordSettings
                UserDefaults.standard.set(darkMode, forKey: "darkMode")
                UserDefaults.standard.set(sortByMostRecent, forKey: "sortByMostRecent")
                UserDefaults.standard.set(pfpShown, forKey: "pfpShown")
                UserDefaults.standard.set(pastel, forKey: "pastelColors")
                UserDefaults.standard.set(self.proxyIP, forKey: "proxyIP")
                UserDefaults.standard.set(self.proxyPort, forKey: "proxyPort")
                UserDefaults.standard.set(self.proxyEnable, forKey: "proxyEnabled")
                UserDefaults.standard.set(self.discordSettings, forKey: "discordStockSettings")

            })
        }
    }
}

// Get memory usage
func report_memory() -> Int {
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    if kerr == KERN_SUCCESS {
        return Int(taskInfo.resident_size)
    } else {
        print("Error with task_info(): " +
            (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
        return 0
    }
}

extension FileManager {

    open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }

}

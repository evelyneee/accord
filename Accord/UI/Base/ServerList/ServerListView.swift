//
//  ServerListView.swift
//  Accord
//
//  Created by evelyn on 2021-06-18.
//

import Combine
import SwiftUI
import UserNotifications

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

struct GuildHoverAnimation: ViewModifier {
    var color: Color = Color.accentColor.opacity(0.5)
    var hasIcon: Bool
    var frame: CGFloat = 45
    var selected: Bool
    @State var hovered: Bool = false

    func body(content: Content) -> some View {
        content
            .onHover(perform: { res in
                withAnimation(Animation.easeInOut(duration: 0.1)) {
                    hovered = res
                }
            })
            .frame(width: frame, height: frame)
            .background(!hasIcon && hovered ? color : Color.clear)
            .cornerRadius(hovered || selected ? 15 : frame / 2)
    }
}

func pingCount(guild: Guild) -> Int {
    let intArray = guild.channels.compactMap { $0.read_state?.mention_count }
    return intArray.reduce(0, +)
}

func unreadMessages(guild: Guild) -> Bool {
    let array = guild.channels
        .filter { $0.read_state != nil }
        .compactMap { $0.last_message_id == $0.read_state?.last_message_id }
        .contains(false)
    return array
}

struct ServerListView: View {
    // i feel bad about this but i need some way to use static vars
    public class UpdateView: ObservableObject {
        @Published var updater: Bool = false
        func updateView() {
            DispatchQueue.main.async {
                self.updater.toggle()
                self.objectWillChange.send()
            }
        }
    }

    @State var selection: Int?
    @State var selectedGuild: Guild?
    var upcomingGuild: Guild?
    var upcomingSelection: Int?
    
    @AppStorage("SelectedServer")
    var selectedServer: String?
    
    public static var folders: [GuildFolder] = .init()
    public static var privateChannels: [Channel] = .init()
    public static var mergedMembers: [String: Guild.MergedMember] = .init()
    internal static var readStates: [ReadStateEntry] = .init()
    var statusText: String?
    @State var status: String?
    @State var bag = Set<AnyCancellable>()
    @StateObject var viewUpdater = UpdateView()
    @State var iconHovered: Bool = false
    @State var isShowingJoinServerSheet: Bool = false

    var onlineButton: some View {
        Button("Offline") {
            AccordApp.error(text: "Offline", additionalDescription: "Check your network connection")
        }
    }

    var statusIndicator: some View {
        Circle()
            .foregroundColor({ () -> Color in
                switch self.status {
                case "online":
                    return Color.green
                case "idle":
                    return Color.orange
                case "dnd":
                    return Color.red
                case "offline":
                    return Color.gray
                default:
                    return Color.clear
                }
            }())
            .frame(width: 7, height: 7)
    }

    var settingsLink: some View {
        NavigationLink(destination: SettingsView(), tag: 0, selection: self.$selection) {
            HStack {
                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: NSImage(data: avatar) ?? NSImage()).resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 24, height: 24)
                    statusIndicator
                }
                VStack(alignment: .leading) {
                    if let user = Globals.user {
                        Text(user.username) + Text("#" + user.discriminator).foregroundColor(.secondary)
                        if let statusText = statusText {
                            Text(statusText)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    // MARK: - Messages button

                    LazyVStack {
                        if !NetworkCore.shared.connected {
                            onlineButton
                                .buttonStyle(BorderlessButtonStyle())
                        }
                        DMButton(
                            selection: self.$selection,
                            selectedServer: self.$selectedServer,
                            selectedGuild: self.$selectedGuild,
                            updater: self.viewUpdater
                        )
                        .fixedSize()
                        Color.gray
                            .frame(width: 30, height: 1)
                            .opacity(0.75)
                        FolderListView(selectedServer: self.$selectedServer, selection: self.$selection, selectedGuild: self.$selectedGuild, updater: self.viewUpdater)
                            .padding(.trailing, 3.5)
                        Color.gray
                            .frame(width: 30, height: 1)
                            .opacity(0.75)
                        JoinServerButton(viewUpdater: self.viewUpdater)
                    }
                }
                .frame(width: 80)
                .padding(.top, 5)
                Divider()

                // MARK: - Loading UI

                if selectedServer == "@me" {
                    List {
                        settingsLink
                        Divider()
                        PrivateChannelsView(
                            privateChannels: Storage.privateChannels,
                            selection: self.$selection,
                            viewUpdater: self.viewUpdater
                        )
                        .animation(nil, value: UUID())
                    }
                    .padding(.top, 5)
                    .listStyle(.sidebar)
                    .animation(nil, value: UUID())
                } else if let selectedGuild = selectedGuild {
                    GuildView(guild: selectedGuild, selection: self.$selection, updater: self.viewUpdater)
                        .animation(nil, value: UUID())
                }
            }
            .frame(minWidth: 300, maxWidth: 500, maxHeight: .infinity)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        // .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Refresh")), perform: { pub in
            guard let uInfo = pub.userInfo as? [String: Int],
                  let firstKey = uInfo.first else { return }
            print(firstKey)
            self.selectedServer = firstKey.key
            self.selection = firstKey.value
            self.selectedGuild = Array(Storage.folders.map(\.guilds).joined())[keyed: firstKey.key]
        })
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DMSelect")), perform: { pub in
            guard let uInfo = pub.userInfo as? [String: String],
                  let index = uInfo["index"], let number = Int(index) else { return }
            self.selectedServer = "@me"
            self.selection = number
        })
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Updater")), perform: { _ in
            viewUpdater.updateView()
        })
        .onAppear {
            if let upcomingGuild = upcomingGuild {
                self.selectedGuild = upcomingGuild
                self.selection = self.upcomingSelection
            }
            DispatchQueue.global().async {
                try? wss?.updatePresence(status: MediaRemoteWrapper.status ?? "offline", since: 0) {
                    Activity.current!
                }
                if UserDefaults.standard.bool(forKey: "XcodeRPC") {
                    guard let workspace = XcodeRPC.getActiveWorkspace() else { return }
                    XcodeRPC.updatePresence(workspace: workspace, filename: XcodeRPC.getActiveFilename())
                } else if UserDefaults.standard.bool(forKey: "AppleMusicRPC") {
                    MediaRemoteWrapper.updatePresence()
                } else if UserDefaults.standard.bool(forKey: "VSCodeRPCEnabled") {
                    VisualStudioCodeRPC.updatePresence()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                if selection == nil {
                    Toggle(isOn: Binding.constant(false)) {
                        Image(systemName: "bell.badge.fill")
                    }
                }
            }
        }
    }
}

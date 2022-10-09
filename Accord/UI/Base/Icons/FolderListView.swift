//
//  FolderListView.swift
//  Accord
//
//  Created by evelyn on 2022-02-14.
//

import Foundation
import SwiftUI

struct FolderListHeightPreferenceKey: PreferenceKey {
    static var defaultValue: Double = 0

    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }

    typealias Value = Double
}

struct InsetGetter: View {
    var body: some View {
        GeometryReader { geometry in
            return Rectangle().fill(Color.clear).preference(key: FolderListHeightPreferenceKey.self, value: geometry.size.height)
        }
    }
}

extension ServerListView {
    struct FolderListView: View {
        @Binding var selectedServer: String?
        @Binding var selectedGuild: Guild?

        @State var isShowingJoinServerSheet: Bool = false
        
        @EnvironmentObject
        var appModel: AppGlobals
        
        func color(_ folder: GuildFolder) -> Color {
            if let color = folder.color {
                return Color(int: color)
            }
            return Color("AccentColor")
        }
        
        
        var body: some View {
            ForEach($appModel.folders, id: \.hashValue) { $folder in
                if folder.guilds.count > 1 {
                    Folder(
                        icon: Array(folder.guilds.prefix(4)),
                        color: self.color(folder),
                        read: folder.guilds.map({ unreadMessages(guild: $0) }).contains(true),
                        mentionCount: folder.guilds.map({ pingCount(guild: $0) }).reduce(0, +)
                    ) {
                        ForEach($folder.guilds, id: \.id) { $guild in
                            ServerIconCell(
                                guild: $guild,
                                selectedServer: self.$selectedServer,
                                selectedChannel: self.$appModel.selectedChannel,
                                selectedGuild: self.$selectedGuild
                            )
                            .fixedSize()
                        }
                    }
                    .padding(.bottom, 1)
                    .id(folder.guilds.first?.id)
                } else if let guild = $folder.guilds.first {
                    ServerIconCell(
                        guild: guild,
                        selectedServer: self.$selectedServer,
                        selectedChannel: self.$appModel.selectedChannel,
                        selectedGuild: self.$selectedGuild
                    )
                    .fixedSize()
                    .id(guild.id)
                }
            }
            .padding(.trailing, 6)
            // .background(InsetGetter())
        }
    }
}

struct ServerIconCell: View {
    @Binding var guild: Guild
    @Binding var selectedServer: String?
    @Binding var selectedChannel: Channel?
    @Binding var selectedGuild: Guild?
    @State var hovering: Bool = false

    @State var mentionCount: Int?
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    @State var offsetY: Double = Double.zero
    @State var viewHeight: Double = Double.zero

    func updateSelection(old: String?, new: String?) {
        DispatchQueue.global().async {
            if let selection = selectedChannel?.id, old == "@me" {
                UserDefaults.standard.set(selection, forKey: "AccordChannelDMs")
            }
            guard let new = new else {
                return DispatchQueue.main.async {
                    self.selectedServer = new
                    self.selectedGuild = guild
                }
            }
            if let selection = selectedChannel?.id, let id = selectedGuild?.id {
                UserDefaults.standard.set(selection, forKey: "AccordChannelIn\(id)")
            }
            DispatchQueue.main.async {
                self.selectedChannel = nil
                if let value = UserDefaults.standard.object(forKey: "AccordChannelIn\(guild.id)") as? String {
                    self.selectedGuild = guild
                    self.selectedServer = new
                    self.selectedChannel = self.selectedGuild?.channels.first(where: { $0.id == value })
                } else {
                    self.selectedGuild = guild
                    self.selectedServer = new
                }
            }
        }
    }

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 5)
                .fill()
                .foregroundColor(Color.primary)
                .frame(width: 5, height: selectedServer == guild.id || hovering ? 30 : 5)
                .animation(Animation.easeInOut(duration: 0.1), value: UUID())
                .opacity(unreadMessages(guild: guild) || selectedServer == guild.id ? 1 : 0)
            GuildListPreview(guild: $guild, selectedServer: $selectedServer.animation())
        }
        .onTapGesture {
            self.updateSelection(old: selectedServer, new: guild.id)
        }
        .accessibility(
            label: Text(guild.name ?? "Unknown Guild") + Text(String(pingCount(guild: guild)) + " mentions") + Text(unreadMessages(guild: guild) ? "Unread messages" : "No unread messages")
        )
        .onHover(perform: { h in withAnimation(Animation.easeInOut(duration: 0.1)) { self.hovering = h } })
        .onReceive(self.appModel.objectWillChange, perform: { _ in
            self.mentionCount = pingCount(guild: guild)
        })
        .onAppear {
            if self.mentionCount == nil {
                self.mentionCount = pingCount(guild: guild)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .redBadge($mentionCount)
//        .onPreferenceChange(FolderListHeightPreferenceKey.self, perform: { self.viewHeight = $0 })
//        .offset(x: 0, y: self.offsetY)
//        .zIndex(self.offsetY == .zero ? -1 : 1)
//        .gesture(
//            DragGesture()
//                .onChanged { gesture in
//                    self.offsetY = gesture.translation.height
//                }
//                .onEnded { gesture in
//                    print(viewHeight / gesture.translation.height)
//                }
//        )
    }
}

//
//  FolderListView.swift
//  Accord
//
//  Created by evelyn on 2022-02-14.
//

import Foundation
import SwiftUI

extension ServerListView {
    struct FolderListView: View {
        @Binding var selectedServer: Int?
        @Binding var selection: Int?
        @Binding var selectedGuild: Guild?
        @StateObject var updater: ServerListView.UpdateView

        var body: some View {
            ForEach(ServerListView.folders, id: \.hashValue) { folder in
                if folder.guilds.count != 1 {
                    Folder(
                        icon: Array(folder.guilds.prefix(4)),
                        color: Color(int: folder.color ?? 0),
                        read: Binding.constant(folder.guilds.map { unreadMessages(guild: $0) }.contains(true))
                    ) {
                        ForEach(folder.guilds, id: \.id) { guild in
                            ServerIconCell(
                                guild: guild,
                                selectedServer: self.$selectedServer,
                                selection: self.$selection,
                                selectedGuild: self.$selectedGuild,
                                updater: self.updater
                            )
                        }
                    }
                    .padding(.bottom, 1)
                } else if let guild = folder.guilds.first {
                    ServerIconCell(
                        guild: guild,
                        selectedServer: self.$selectedServer,
                        selection: self.$selection,
                        selectedGuild: self.$selectedGuild,
                        updater: self.updater
                    )
                }
            }
            .padding(.trailing, 6)
        }
    }
}

struct ServerIconCell: View {
    var guild: Guild
    @Binding var selectedServer: Int?
    @Binding var selection: Int?
    @Binding var selectedGuild: Guild?
    @State var hovering: Bool = false
    @StateObject var updater: ServerListView.UpdateView

    func updateSelection(old: Int?, new: Int?) {
        DispatchQueue.global().async {
            if old == 201 {
                if let selection = selection {
                    UserDefaults.standard.set(selection, forKey: "AccordChannelDMs")
                }
            }
            let map = Array(ServerListView.folders.compactMap { $0.guilds }.joined())
            guard let selectedServer = old,
                  let new = new,
                  let newID = map[safe: new]?.id else {
                DispatchQueue.main.async {
                    self.selectedServer = new
                    self.selectedGuild = guild
                }
                return
            }
            if let selection = selection, let id = map[safe: selectedServer]?.id {
                UserDefaults.standard.set(selection, forKey: "AccordChannelIn\(id)")
            }
            DispatchQueue.main.async {
                self.selection = nil
                withAnimation(old == 201 ? nil : Animation.linear(duration: 0.1)) {
                    if let value = UserDefaults.standard.object(forKey: "AccordChannelIn\(newID)") as? Int {
                        self.selection = value
                        self.selectedGuild = guild
                        self.selectedServer = new
                    } else {
                        self.selectedGuild = guild
                        self.selectedServer = new
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: { [weak wss] in
                wss?.cachedMemberRequest.removeAll()
                self.updateSelection(old: selectedServer, new: guild.index)
            }) {
                HStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill()
                        .foregroundColor(Color.primary)
                        .frame(width: 5, height: selectedServer == guild.index || hovering ? 30 : 5)
                        .animation(Animation.linear(duration: 0.1))
                        .opacity(unreadMessages(guild: guild) || selectedServer == guild.index ? 1 : 0)
                    GuildListPreview(guild: guild, selectedServer: $selectedServer.animation(), updater: updater)
                }
            }
            .accessibility(
                label: Text(guild.name ?? "Unknown Guild") + Text(String(pingCount(guild: guild)) + " mentions") + Text(unreadMessages(guild: guild) ? "Unread messages" : "No unread messages")
            )
            .onHover(perform: { h in withAnimation(Animation.linear(duration: 0.1)) {self.hovering = h} })
            .buttonStyle(BorderlessButtonStyle())
            if pingCount(guild: guild) != 0 {
                ZStack {
                    Circle()
                        .foregroundColor(.red)
                        .frame(width: 15, height: 15)
                    Text(String(pingCount(guild: guild)))
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .font(.caption)
                }
            }
        }
    }
}

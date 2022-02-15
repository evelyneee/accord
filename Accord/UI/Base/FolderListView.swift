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
        var body: some View {
            ForEach(ServerListView.folders, id: \.hashValue) { folder in
                if folder.guilds.count != 1 {
                    HStack {
                        Circle()
                            .fill()
                            .foregroundColor(Color.white)
                            .frame(width: 5, height: 5)
                            .if(!folder.unreadMessages, transform: { $0.opacity(0) })
                        Folder(icon: Array(folder.guilds.prefix(4)), color: NSColor.color(from: folder.color ?? 0) ?? NSColor.windowBackgroundColor) {
                            ForEach(folder.guilds, id: \.hashValue) { guild in
                                ZStack(alignment: .bottomTrailing) {
                                    Button(action: { [weak wss] in
                                        wss?.cachedMemberRequest.removeAll()
                                        if selectedServer == 201 {
                                            selectedServer = guild.index
                                        } else {
                                            withAnimation {
                                                let oldSelection = selectedServer
                                                concurrentQueue.async {
                                                    let map = Array(ServerListView.folders.compactMap { $0.guilds }.joined())
                                                    guard let selectedServer = oldSelection,
                                                          let new = guild.index,
                                                          let id = map[safe: selectedServer]?.id,
                                                          let newID = map[safe: new]?.id else { return }
                                                    UserDefaults.standard.set(self.selection, forKey: "AccordChannelIn\(id)")
                                                    let val = UserDefaults.standard.integer(forKey: "AccordChannelIn\(newID)")
                                                    DispatchQueue.main.async {
                                                        if val != 0 {
                                                            self.selection = val
                                                        }
                                                    }
                                                }
                                                selectedServer = guild.index
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill()
                                                .foregroundColor(Color.white)
                                                .frame(width: 5, height: 5)
                                                .if(!unreadMessages(guild: guild), transform: { $0.opacity(0) })
                                            Attachment(iconURL(guild.id, guild.icon ?? "")).equatable()
                                                .frame(width: 45, height: 45)
                                                .cornerRadius(selectedServer == guild.index ? 15.0 : 23.5)
                                        }
                                    }
                                    if pingCount(guild: guild) != 0 {
                                        ZStack {
                                            Circle()
                                                .foregroundColor(Color.red)
                                                .frame(width: 15, height: 15)
                                            Text(String(pingCount(guild: guild)))
                                                .foregroundColor(Color.white)
                                                .fontWeight(.semibold)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 1)
                    }
                } else {
                    ZStack(alignment: .bottomTrailing) {
                        ForEach(folder.guilds, id: \.hashValue) { guild in
                            Button(action: { [weak wss] in
                                wss?.cachedMemberRequest.removeAll()
                                if selectedServer == 201 {
                                    selectedServer = guild.index
                                } else {
                                    withAnimation {
                                        let oldSelection = selectedServer
                                        concurrentQueue.async {
                                            let map = Array(ServerListView.folders.compactMap { $0.guilds }.joined())
                                            guard let selectedServer = oldSelection,
                                                  let new = guild.index,
                                                  let id = map[safe: selectedServer]?.id,
                                                  let newID = map[safe: new]?.id else { return }
                                            UserDefaults.standard.set(self.selection, forKey: "AccordChannelIn\(id)")
                                            let val = UserDefaults.standard.integer(forKey: "AccordChannelIn\(newID)")
                                            DispatchQueue.main.async {
                                                if val != 0 {
                                                    self.selection = val
                                                }
                                            }
                                        }
                                        selectedServer = guild.index
                                    }
                                }
                            }) {
                                HStack {
                                    Circle()
                                        .fill()
                                        .foregroundColor(Color.white)
                                        .frame(width: 5, height: 5)
                                        .if(!unreadMessages(guild: guild), transform: { $0.opacity(0) })
                                    Attachment(iconURL(guild.id, guild.icon ?? "")).equatable()
                                        .frame(width: 45, height: 45)
                                        .cornerRadius(selectedServer == guild.index ? 15.0 : 23.5)
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            if pingCount(guild: guild) != 0 {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color.red)
                                        .frame(width: 15, height: 15)
                                    Text(String(pingCount(guild: guild)))
                                        .foregroundColor(Color.white)
                                        .fontWeight(.semibold)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

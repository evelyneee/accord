//
//  DMButton.swift
//  Accord
//
//  Created by evelyn on 2022-05-17.
//

import SwiftUI

struct DMButton: View {
    @Binding var selection: Int?
    @Binding var selectedServer: Int?
    @Binding var selectedGuild: Guild?
    @StateObject var updater: ServerListView.UpdateView
    @State var mentionCount: Int?
    @State var iconHovered: Bool = false
    var body: some View {
        Button(action: {
            DispatchQueue.global().async {
                wss?.cachedMemberRequest.removeAll()
                ServerListView.privateChannels = ServerListView.privateChannels.sorted(by: { $0.last_message_id ?? "" > $1.last_message_id ?? "" })
            }
            if let selection = selection, let id = self.selectedGuild?.id {
                UserDefaults.standard.set(selection, forKey: "AccordChannelIn\(id)")
            }
            selectedServer = 201
            selection = nil
            self.selectedGuild = nil
            if let selectionPrevious = UserDefaults.standard.object(forKey: "AccordChannelDMs") as? Int {
                self.selection = selectionPrevious
            }
        }) {
            Image(systemName: "bubble.right.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
                .padding()
                .frame(width: 45, height: 45)
                .background(selectedServer == 201 || iconHovered ? Color.accentColor.opacity(0.5) : Color(NSColor.windowBackgroundColor))
                .cornerRadius(iconHovered || selectedServer == 201 ? 13.5 : 23.5)
                .foregroundColor(selectedServer == 201 || iconHovered ? Color.white : nil)
                .onHover(perform: { h in withAnimation(Animation.easeInOut(duration: 0.2)) { self.iconHovered = h } })
        }
        .redBadge($mentionCount)
        .buttonStyle(BorderlessButtonStyle())
        .onReceive(self.updater.$updater, perform: { _ in
            DispatchQueue.global().async {
                self.mentionCount = ServerListView.privateChannels.compactMap({ $0.read_state?.mention_count }).reduce(0, +)
            }
        })
    }
}

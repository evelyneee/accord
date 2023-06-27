//
//  DMButton.swift
//  Accord
//
//  Created by evelyn on 2022-05-17.
//

import SwiftUI

struct DMButton: View {
    
    @Binding var selectedServer: String?
    @Binding var selectedGuild: Guild?
    @State var mentionCount: Int?
    @State var iconHovered: Bool = false
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    var body: some View {
        Button(action: { [weak appModel] in
            guard let appModel = appModel else { return }
            DispatchQueue.global().async {
                let sorted = appModel.privateChannels
                    .sorted {
                        $0.lastMessageDate > $1.lastMessageDate
                    }
                DispatchQueue.main.async {
                    appModel.privateChannels = sorted
                }
            }
            if let selection = appModel.selectedChannel, let id = self.selectedGuild?.id {
                UserDefaults.standard.set(selection.id, forKey: "AccordChannelIn\(id)")
            }
            selectedServer = "@me"
            self.selectedGuild = nil
            if let selectionPrevious = UserDefaults.standard.object(forKey: "AccordChannelDMs") as? String {
                self.appModel.selectedChannel = self.appModel.privateChannels.first(where: { $0.id == selectionPrevious })
            } else {
                appModel.selectedChannel = nil
            }
        }) {
            Image(systemName: "message.fill")
                .font(.system(size: 20))
                .padding()
                .frame(width: 50, height: 50)
                .background(selectedServer == "@me" || iconHovered ? Color.accentColor.opacity(0.5) : Color(NSColor.secondaryLabelColor).opacity(0.2))
                .cornerRadius(iconHovered || selectedServer == "@me" ? 13.5 : 23.5)
                .foregroundColor(selectedServer == "@me" || iconHovered ? Color.white : nil)
                .onHover(perform: { h in withAnimation(Animation.easeInOut(duration: 0.2)) { self.iconHovered = h } })
        }
        .redBadge($mentionCount)
        .buttonStyle(BorderlessButtonStyle())
        .onReceive(self.appModel.$privateChannels, perform: { _ in
            self.mentionCount = appModel.privateChannels.compactMap { $0.read_state?.mention_count }.reduce(0, +)
        })
    }
}

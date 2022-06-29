//
//  DMButton.swift
//  Accord
//
//  Created by evelyn on 2022-05-17.
//

import SwiftUI

struct DMButton: View {
    
    @Binding var selection: Int?
    @Binding var selectedServer: String?
    @Binding var selectedGuild: Guild?
    @State var mentionCount: Int?
    @State var iconHovered: Bool = false
    
    @EnvironmentObject
    var appModel: AppGlobals
    
    var body: some View {
        Button(action: {
            DispatchQueue.global().async {
                let sorted = appModel.privateChannels.sorted(by: { $0.last_message_id ?? "" > $1.last_message_id ?? "" })
                DispatchQueue.main.async {
                    appModel.privateChannels = sorted
                }
            }
            if let selection = selection, let id = self.selectedGuild?.id {
                UserDefaults.standard.set(selection, forKey: "AccordChannelIn\(id)")
            }
            selectedServer = "@me"
            //self.selectedGuild = nil
            if let selectionPrevious = UserDefaults.standard.object(forKey: "AccordChannelDMs") as? Int {
                self.selection = selectionPrevious
            } else {
                selection = nil
            }
        }) {
            Image(systemName: "bubble.right.fill")
                .font(.system(size: 16))
                .padding()
                .frame(width: 45, height: 45)
                .background(selectedServer == "@me" || iconHovered ? Color.accentColor.opacity(0.5) : Color(NSColor.windowBackgroundColor))
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

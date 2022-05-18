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
    @StateObject var updater: ServerListView.UpdateView
    @State var mentionCount: Int?
    @State var iconHovered: Bool = false
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: {
                selection = nil
                DispatchQueue.global().async {
                    wss?.cachedMemberRequest.removeAll()
                    ServerListView.privateChannels = ServerListView.privateChannels.sorted(by: { $0.last_message_id ?? "" > $1.last_message_id ?? "" })
                }
                selectedServer = 201
                let prevSelection = selection
                if let selectionPrevious = UserDefaults.standard.object(forKey: "AccordChannelDMs") as? Int {
                    self.selection = selectionPrevious
                }
                if let selection = prevSelection {
                    UserDefaults.standard.set(selection, forKey: "AccordChannelDMs")
                }
            }) {
                Image(systemName: "bubble.right.fill")
                    .imageScale(.medium)
                    .frame(width: 45, height: 45)
                    .background(selectedServer == 201 ? Color.accentColor.opacity(0.5) : Color(NSColor.windowBackgroundColor))
                    .cornerRadius(iconHovered || selectedServer == 201 ? 13.5 : 23.5)
                    .if(selectedServer == 201, transform: { $0.foregroundColor(Color.white) })
                    .onHover(perform: { h in withAnimation(Animation.linear(duration: 0.1)) { self.iconHovered = h } })
            }
            if let mentionCount = mentionCount, mentionCount != 0 {
                ZStack {
                    Circle()
                        .foregroundColor(Color.red)
                        .frame(width: 15, height: 15)
                    Text(String(mentionCount))
                        .foregroundColor(Color.white)
                        .fontWeight(.semibold)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .onReceive(self.updater.$updater, perform: { _ in
            DispatchQueue.global().async {
                self.mentionCount = ServerListView.privateChannels.compactMap({ $0.read_state?.mention_count }).reduce(0, +)
            }
        })
    }
}

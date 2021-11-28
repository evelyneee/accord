//
//  QuickActionsView.swift
//  Accord
//
//  Created by evelyn on 2021-11-27.
//

import Foundation
import SwiftUI

struct QuickActionsView: View, Equatable {
    
    static func == (lhs: QuickActionsView, rhs: QuickActionsView) -> Bool {
        return lhs.opened == rhs.opened
    }
    
    @Binding var message: Message
    @Binding var replyingTo: Message?
    @Binding var opened: Bool
    
    var openButton: some View {
        Button(action: {
            opened.toggle()
        }) {
            Image(systemName: (opened ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
        }
    }
    
    var clipButton: some View {
        Button(action: { [weak message] in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString((message?.content ?? "").marked(), forType: .string)
            opened.toggle()
        }) {
            Text("Copy")
        }
    }
    
    var linkButton: some View {
        Button(action: { [weak message] in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("https://discord.com/channels/\(message?.guild_id ?? "@me")/\(message!.channel_id)/\(message?.id ?? "")", forType: .string)
            opened.toggle()
        }) {
            Text("Copy Message Link")
        }
    }
    
    var replyButton: some View {
        Button(action: { [weak message] in
            replyingTo = message
        }) {
            Image(systemName: "arrowshape.turn.up.backward.fill")
        }
    }
    
    var deleteButton: some View {
        Button(action: { [weak message] in
            DispatchQueue.global(qos: .background).async {
                message?.delete()
            }
        }) {
            Image(systemName: "trash")
        }
    }
    
    var body: some View {
        HStack {
            openButton
            if opened {
                clipButton
                linkButton
            }
            replyButton
            deleteButton
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

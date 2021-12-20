//
//  QuickActionsView.swift
//  Accord
//
//  Created by evelyn on 2021-11-27.
//

import Foundation
import SwiftUI

struct QuickActionsView: View {
    
    weak var message: Message?
    
    @Binding var replyingTo: Message?
    @State var opened: Bool = false
    
    var openButton: some View {
        Button(action: {
            opened.toggle()
        }) {
            Image(systemName: (opened ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
        }
    }
    
    var replyButton: some View {
        Button(action: {
            replyingTo = message
        }) {
            Image(systemName: "arrowshape.turn.up.backward.fill")
        }
    }
    
    var deleteButton: some View {
        Button(action: {
            DispatchQueue.global(qos: .background).async {
                message?.delete()
            }
        }) {
            Image(systemName: "trash")
        }
    }
    
    var body: some View {
        lazy var clipButton = {
            return Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString((message?.content ?? "").marked(), forType: .string)
                opened.toggle()
            }) {
                Text("Copy")
            }
        }()
        
        lazy var linkButton = {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("https://discord.com/channels/\(message?.guild_id ?? "@me")/\(message!.channel_id)/\(message?.id ?? "")", forType: .string)
                opened.toggle()
            }) {
                Text("Copy Message Link")
            }
        }()
        
        return HStack {
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

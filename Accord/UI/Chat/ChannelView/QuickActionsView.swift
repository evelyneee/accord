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
        Image(systemName: (opened ? "arrow.right.circle.fill" : "arrow.left.circle.fill"))
            .foregroundColor(Color.secondary)
            .onTapGesture {
                withAnimation {
                    opened.toggle()
                }
            }
    }

    var replyButton: some View {
        Image(systemName: "arrowshape.turn.up.backward.fill")
            .foregroundColor(Color.secondary)
            .onTapGesture {
                replyingTo = message
            }
    }

    var deleteButton: some View {
        Image(systemName: "trash")
            .foregroundColor(Color.secondary)
            .onTapGesture {
                DispatchQueue.global(qos: .background).async {
                    message?.delete()
                }
            }
    }

    var body: some View {
        lazy var clipButton = {
            Text("Copy")
                .foregroundColor(Color.secondary)
                .onTapGesture {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString((message?.content ?? ""), forType: .string)
                    opened.toggle()
                }
        }()

        lazy var linkButton = {
            Text("Copy Message Link")
                .foregroundColor(Color.secondary)
                .onTapGesture {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("https://discord.com/channels/\(message?.guild_id ?? "@me")/\(message!.channel_id)/\(message?.id ?? "")", forType: .string)
                    opened.toggle()
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

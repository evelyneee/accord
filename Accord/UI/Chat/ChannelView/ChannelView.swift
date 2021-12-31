//
//  ChannelView.swift
//  Accord
//
//  Created by evelyn on 2020-11-27.
//

import SwiftUI
import AppKit
import AVKit

final class ChannelMembers {
    static var shared = ChannelMembers()
    var channelMembers: [String: [String: String]] = [:]
}

struct ChannelView: View, Equatable {

    // MARK: - Equatable protocol
    static func == (lhs: ChannelView, rhs: ChannelView) -> Bool {
        return lhs.viewModel.messages == rhs.viewModel.messages
    }

    @ObservedObject var viewModel: ChannelViewViewModel

    var guildID: String
    var channelID: String
    var channelName: String
    var guildName: String

    // Whether or not there is a message send in progress
    @State var sending: Bool = false

    // Nicknames/Usernames of users typing
    @State var typing: [String] = []

    // Collapsed message quick action indexes

    // WebSocket error
    @State var error: String?

    // Mention users in replies
    @State var mention: Bool = true
    @State var replyingTo: Message?

    @State var pins: Bool = false
    @State var mentions: Bool = false

    var messageMap: [String: Int?] {
        return viewModel.messages.enumerated().compactMap { (index, element) in
            return [element.id: index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
    }

    // MARK: - init
    init(_ channel: Channel, _ guildName: String? = nil) {
        self.guildID = channel.guild_id ?? "@me"
        self.channelID = channel.id
        self.channelName = channel.name ?? channel.recipients?[safe: 0]?.username ?? "Unknown channel"
        self.guildName = guildName ?? "Direct Messages"
        self.viewModel = ChannelViewViewModel(channelID: channelID, guildID: guildID)
    }

    var body: some View {
        ZStack(alignment: .bottom) { [weak viewModel] in
            List {
                ForEach($viewModel.messages, id: \.identifier) { $message in
                    MessageCellView(message: message, nick: viewModel?.nicks[message.author?.id ?? ""], replyNick: viewModel?.nicks[message.referenced_message?.author?.id ?? ""], pronouns: viewModel?.pronouns[message.author?.id ?? ""], role: $viewModel.roles[message.author?.id ?? ""], replyRole: $viewModel.roles[message.referenced_message?.author?.id ?? ""], replyingTo: $replyingTo)
                }
                Spacer().frame(height: 90)
            }
            blurredTextField
        }
        .navigationTitle(Text("\(guildID == "@me" ? "" : "#")\(channelName)"))
        .navigationSubtitle(Text(guildName))
        .presentedWindowToolbarStyle(UnifiedCompactWindowToolbarStyle())
        .onAppear {
            // Make Gateway messages receivable now
            MessageController.shared.delegates[channelID] = self
        }
        .onDisappear {
            MessageController.shared.delegates.removeValue(forKey: channelID)
        }
        .toolbar {
            ToolbarItemGroup {
                Toggle(isOn: $pins) {
                    Image(systemName: "pin.fill")
                        .rotationEffect(.degrees(45))
                }
                .popover(isPresented: $pins) {
                    PinsView(guildID: guildID, channelID: channelID)
                        .frame(width: 500, height: 600)
                }
                Toggle(isOn: $mentions) {
                    Image(systemName: "bell.badge.fill")
                }
                .popover(isPresented: $mentions) {
                    MentionsView()
                        .frame(width: 500, height: 600)
                }
            }
        }
    }
}

// MARK: - macOS Big Sur blur view

public struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    public init(
        material: NSVisualEffectView.Material = .contentBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = NSVisualEffectView.State.active
        return visualEffectView
    }

    public func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

// prevent index out of range
public extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

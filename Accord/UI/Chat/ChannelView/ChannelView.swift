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
    var channelMembers: [String:[String:String]] = [:]
}

// MARK: - Threads

let concurrentQueue = DispatchQueue(label: "UpdatingQueue", attributes: .concurrent)
let webSocketQueue = DispatchQueue(label: "WebSocketQueue", attributes: .concurrent)

struct ChannelView: View, Equatable {

    // MARK: - Equatable protocol
    static func == (lhs: ChannelView, rhs: ChannelView) -> Bool {
        return lhs.viewModel.messages == rhs.viewModel.messages
    }

    @ObservedObject var viewModel: ChannelViewViewModel
    
    var guildID: String
    var channelID: String
    var channelName: String

    // Whether or not there is a message send in progress
    @State var sending: Bool = false

    // Nicknames/Usernames of users typing
    @State var typing: [String] = []

    // Collapsed message quick action indexes
    @State var collapsed: [Int] = []
    @State var popup: [Bool] = Array.init(repeating: false, count: 50)
    @State var sidePopups: [Bool] = Array.init(repeating: false, count: 50)

    // WebSocket error
    @State var error: String? = nil

    // Mention users in replies
    @State var mention: Bool = true
    @State var replyingTo: Message? = nil

    // Editing
    @State var editing: String? = nil
    
    @State var opened: Int? = nil
    
    var messageMap: [String:Int?] {
        return viewModel.messages.enumerated().compactMap { (index, element) in
            return [element.id:index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
    }
    
    fileprivate static var set = false
    
    // MARK: - init
    init(_ channel: Channel) {
        self.guildID = channel.guild_id ?? "@me"
        self.channelID = channel.id
        self.channelName = channel.name ?? channel.recipients?[safe: 0]?.username ?? "Unknown channel"
        self.viewModel = ChannelViewViewModel(channelID: channelID, guildID: guildID)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) { [weak viewModel] in
            List {
                ForEach($viewModel.messages, id: \.id) { $message in
                    MessageCellView(message: $message, nick: viewModel?.nicks[message.author?.id ?? ""], replyNick: viewModel?.nicks[message.referenced_message?.author?.id ?? ""], pronouns: viewModel?.pronouns[message.author?.id ?? ""], role: $viewModel.roles[message.author?.id ?? ""], replyRole: $viewModel.roles[message.referenced_message?.author?.id ?? ""], replyingTo: $replyingTo)
                }
                Spacer().frame(height: 90)
            }
            blurredTextField
        }
        .onAppear {
            // Make Gateway messages receivable now
            MessageController.shared.delegates[channelID] = self
        }
        .onDisappear {
            MessageController.shared.delegates.removeValue(forKey: channelID)
            ChannelView.set = false
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

//
//  MentionView.swift
//  Accord
//
//  Created by evelyn on 2021-10-23.
//

import SwiftUI

struct MentionView: View {
    @ObservedObject var viewModel = MentionViewViewModel()
    @Binding var query: String
    var body: some View {
        List(viewModel.results, id: \.id) { user in
            Text(user.username)
        }
        .background(VisualEffectView.init(material: NSVisualEffectView.Material.sidebar, blendingMode: .behindWindow))
        .onChange(of: $query.wrappedValue, perform: { _ in
            viewModel.userSearch(user: query)
        })
    }
}

final class MentionViewViewModel: ObservableObject {
    
    @Published var results = [User]()
    
    var matches = [GuildMember]() {
        didSet {
            handleUserSearch()
        }
    }
    
    init() {
        
    }
    
    func userSearch(user: String) {
        
    }
    
    func handleUserSearch() {
        
    }
    
}

extension MentionView: MessageControllerDelegate {
    
    func sendMemberChunk(msg: Data) {
        guard let chunk = try? JSONDecoder().decode(GuildMemberChunkResponse.self, from: msg) else { return }
        guard let users = chunk.d?.members else { return }
        viewModel.matches = users.compactMap { $0 }
    }
    
    func sendMessage(msg: Data, channelID: String?) {}
    func editMessage(msg: Data, channelID: String?) {}
    func deleteMessage(msg: Data, channelID: String?) {}
    func typing(msg: [String : Any], channelID: String?) {}
    func sendWSError(msg: String) {}
}

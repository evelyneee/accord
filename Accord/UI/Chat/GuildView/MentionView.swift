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
    @Binding var userArray: [User]
    var body: some View {
        List(viewModel.results, id: \.id) { user in
            Text(user.username)
        }
        .onChange(of: query, perform: { _ in
            viewModel.userSearch(user: query, in: userArray)
        })
    }
}

final class MentionViewViewModel: ObservableObject {

    @Published var results = [User]()
    
    init() {
        
    }
    
    func userSearch(user: String, in userArray: [User]) {
        results = userArray.filter { $0.username.contains(user) }
    }
    
}

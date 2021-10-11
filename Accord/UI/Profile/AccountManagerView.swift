//
//  AccountManagerView.swift
//  AccountManagerView
//
//  Created by evelyn on 2021-08-07.
//

import SwiftUI

let jsonString: [String:String] = [
    "id":"cock",
    "token":"balls",
    "username":"evln",
    "discriminator":"0001",
    "avatar":"balls"
]

class Account: Decodable, Identifiable, Hashable {
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.token == rhs.token
    }
    
    var id: String
    var token: String
    var username: String
    var discriminator: String
    var avatar: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(token)
    }
}

struct AccountManagerView: View {
    @State var accounts: [Account] = []
    var body: some View {
        VStack {
            List(accounts, id: \.self) { account in
                Text(account.username)
            }
            .onAppear(perform: {
                do {
                    let data = try JSONSerialization.data(withJSONObject: jsonString, options: [])
                    accounts = try JSONDecoder().decode([Account].self, from: data)
                } catch {
                    print(error.localizedDescription)
                }
            })
        }
    }
}

struct AccountManagerView_Previews: PreviewProvider {
    static var previews: some View {
        AccountManagerView()
    }
}

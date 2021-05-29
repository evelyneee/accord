//
//  LoginView.swift
//  Helselia
//
//  Created by Évelyne on 2021-05-23.
//

import SwiftUI

struct LoginView: View {
    @State var username: String = "ebel@helselia.dev"
    @State private var passcode: String = "ebelanger27"
    var body: some View {
        VStack {
            Text("Login to Helselia")
                .font(.title)
                .fontWeight(.bold)
            TextField("Username or Email", text: $username)
            TextField("Password", text: $passcode)
            Button(action: {
                let response = net.request(url: "https://constanze.live/api/v1/auth/login", token: nil, Cookie: "__cfduid=d9ee4b332e29b7a9b1e0befca2ac718461620217863", json: false, type: .POST, bodyObject: ["email":username, "password":passcode])
                print(response)
            }) {
                
            }
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

//
//  LoginView.swift
//  Helselia
//
//  Created by Évelyne on 2021-05-23.
//

import SwiftUI

struct LoginView: View {
    @State var token: String = ""
    @Environment(\.presentationMode) var shown
    var body: some View {
        VStack {
            Text("Login to Discord")
                .font(.title)
                .fontWeight(.bold)
            TextField("Token", text: $token)
            Button(action: {
                KeychainManager.save(key: "token", data: token.data(using: String.Encoding.utf8) ?? Data())
                token = String(decoding: KeychainManager.load(key: "token") ?? Data(), as: UTF8.self)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "logged_in"), object: nil)
                    print("logged in")
                }
                self.shown.wrappedValue.dismiss()
                
            }) {
                HStack {
                    Text("Login")
                }
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

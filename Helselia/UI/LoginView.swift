//
//  LoginView.swift
//  Helselia
//
//  Created by Évelyne on 2021-05-23.
//

import SwiftUI

struct LoginView: View {
    @State var username: String = ""
    @State private var passcode: String = ""
    @Environment(\.presentationMode) var shown
    var body: some View {
        VStack {
            Text("Login to Helselia")
                .font(.title)
                .fontWeight(.bold)
            TextField("Username or Email", text: $username)
            TextField("Password", text: $passcode)
            Button(action: {
                NetworkHandling.shared.login(username: username, password: passcode) { success, rettoken in
                    if (success) {
                        token = rettoken ?? ""
                        UserDefaults.standard.set(token, forKey: "token")
                        self.shown.wrappedValue.dismiss()
                    }
                }
                
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

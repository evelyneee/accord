//
//  WelcomeMessageView.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct WelcomeMessageView: View {
    
    var user: User
    
    var body: some View {
        Label(title: {
            Text("Welcome, ") +
            Text(user.username).fontWeight(.semibold) +
            Text("!")
        }, icon: {
            Image(systemName: "arrow.forward").foregroundColor(.green)
        })
    }
}

//
//  ServerBoost.swift
//  Accord
//
//  Created by evelyn on 2022-08-11.
//

import SwiftUI

struct ServerBoostView: View {
    var user: User
    var body: some View {
        Label(title: {
            Text(user.username).fontWeight(.semibold) +
            Text(" just boosted the server!")
        }, icon: {
            Image(systemName: "star.fill")
        })
    }
}

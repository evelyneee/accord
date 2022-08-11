//
//  MessagePinView.swift
//  Accord
//
//  Created by charlotte on 2022-07-27.
//

import SwiftUI

struct MessagePinView: View {
    var user: User
    var body: some View {
        Label(title: {
            Text(user.username).fontWeight(.semibold) +
            Text(" pinned a message to this channel.")
        }, icon: {
            Image(systemName: "pin.fill").rotationEffect(.degrees(45))
        })
    }
}

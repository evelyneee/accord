//
//  RecipientAddView.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct RecipientAddView: View {
    
    var message: Message
    
    @ViewBuilder
    var body: some View {
        if let username = message.author?.username,
           let added = message.mentions.first {
            Label(title: {
                Text(username).fontWeight(.semibold)
                + Text(" added ")
                + Text(added.username).fontWeight(.semibold)
                + Text(" to the group")
            }, icon: {
                Image(systemName: "arrow.forward").foregroundColor(.green)
            })
        }
    }
}

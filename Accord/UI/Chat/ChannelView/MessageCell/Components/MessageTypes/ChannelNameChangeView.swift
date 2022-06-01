//
//  ChannelNameChangeView.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct ChannelNameChangeView: View {
    
    var user: User
    
    var body: some View {
        Label(title: {
            Text(user.username).fontWeight(.semibold)
            + Text(" changed the channel name")
        }, icon: {
            Image(systemName: "pencil")
        })
    }
}

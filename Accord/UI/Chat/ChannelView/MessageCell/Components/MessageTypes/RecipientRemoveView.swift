//
//  RecipientRemoveView.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct RecipientRemoveView: View {
    
    var user: User
    
    var body: some View {
        Label(title: {
            Text(user.username).fontWeight(.semibold)
            + Text(" left the group")
        }, icon: {
            Image(systemName: "arrow.backward").foregroundColor(.red)
        })
    }
}

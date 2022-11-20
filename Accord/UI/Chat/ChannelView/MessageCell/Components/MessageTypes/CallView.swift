//
//  CallView.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct CallView: View {
    var user: User

    var body: some View {
        Label(user.username + " started a call.", image: "phone.fill")
    }
}

//
//  GuildView+HeaderView.swift
//  GuildView+HeaderView
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

extension GuildView {
    var headerView: some View {
        return HStack {
            VStack(alignment: .leading) {
                Text("This is the beginning of #\(channelName)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding(.vertical)
        .rotationEffect(.radians(.pi))
        .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

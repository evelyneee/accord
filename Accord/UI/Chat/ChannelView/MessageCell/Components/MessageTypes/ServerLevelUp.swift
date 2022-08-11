//
//  ServerLevelUp.swift
//  Accord
//
//  Created by evelyn on 2022-08-11.
//

import SwiftUI

struct ServerLevelUpView: View {
    var level: Int
    
    var levelSymbol: String {
        switch level {
        case 1: return "diamond"
        case 2: return "diamond.bottomhalf.filled"
        case 3: return "diamond.inset.filled"
        default: return ""
        }
    }
    
    var body: some View {
        Label(title: {
            Text("The server reached level \(level)!")
        }, icon: {
            Image(systemName: levelSymbol)
        })
    }
}

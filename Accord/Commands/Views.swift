//
//  Views.swift
//  Accord
//
//  Created by evelyn on 2022-01-21.
//

import Foundation
import SwiftUI

#if DEBUG // Code removed from compilation

    struct SlashCommandEditor: View {
        @State var mainText: String = ""
        @State var arguments: [(label: String, text: String, type: String)] = [(label: "user", text: "", type: "user"), (label: "reason", text: "", type: "value")]

        init() {}

        var body: some View {
            HStack {
                TextField("Enter Command", text: $mainText, onEditingChanged: { _ in
                    // Autocomplete generation here
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                ForEach($arguments, id: \.self.0) { $tuple in
                    HStack {
                        Text("\(tuple.0): ")
                        TextField(tuple.2, text: $tuple.1, onEditingChanged: { _ in
                            // Autocomplete generation here
                        })
                        .frame(width: 100)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                Button(action: {
                    // SlashCommands.interact(applicationID: <#T##String#>, guildID: <#T##String#>, channelID: <#T##String#>, appVersion: <#T##String#>, id: <#T##String#>, dataType: <#T##Int#>, appName: <#T##String#>)
                }) {}
            }
        }
    }

    struct Preview: PreviewProvider {
        static var previews: some View {
            SlashCommandEditor()
        }
    }

#endif

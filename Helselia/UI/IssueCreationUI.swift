//
//  IssueCreationUI.swift
//  Helselia
//
//  Created by evelyn on 2020-12-18.
//

import SwiftUI

struct IssueCreationUI: View {
    @Environment(\.presentationMode) var presentationMode
    @State var showingSettings = true
    @State var issueTitle: String = ""
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Create an issue")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.title)
                }
                .padding(4)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            TextField("Title here", text: $issueTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(EdgeInsets())
                .padding()
            Spacer()
            Button(action: {
                issueContainer.append(issueTitle)
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Submit")
            }
            .padding()
        }
    }
}

struct IssueCreationUI_Previews: PreviewProvider {
    static var previews: some View {
        IssueCreationUI()
    }
}

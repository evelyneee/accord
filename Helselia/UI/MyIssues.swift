//
//  MyIssues.swift
//  Helselia
//
//  Created by evelyn on 2020-11-27.
//

import SwiftUI

struct MyIssues: View {
    @State var showingCreationView = false
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("My Issues")
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .padding()
                }
                Spacer()
                Button(action: {
                    self.showingCreationView.toggle()
                }) {
                    Image(systemName: "plus.bubble.fill")
                        .font(.title)
                }.sheet(isPresented: $showingCreationView) {
                    IssueCreationUI()
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding()
            }
            Spacer()
        }

    }
}

struct MyIssues_Previews: PreviewProvider {
    static var previews: some View {
        MyIssues()
    }
}

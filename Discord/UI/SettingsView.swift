//
//  SettingsView.swift
//  Helselia
//
//  Created by evelyn on 2020-12-08.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var showingSettings = true
    @State public var showPFP = UserDefaults.standard.bool(forKey: "pfpShown")
    @State var usernameSettings: String = ""
    @State var pronounSettings: String = ""
    @State var referenceTitle: String = ""
    @State var referenceLink: String = ""
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                    }
                    .padding()
                    .buttonStyle(BorderlessButtonStyle())
                }

            }

            Spacer()
            ScrollView {
                HStack(alignment: .top) {
                    Text("Show profile pictures")
                        .padding()
                    Spacer()
                    Toggle(isOn: $showPFP) {
                    }
                    .onDisappear(perform: {
                        UserDefaults.standard.set(showPFP, forKey: "pfpShown")
                        pfpShown = UserDefaults.standard.bool(forKey: "pfpShown")
                    })
                    .padding()
                    .toggleStyle(SwitchToggleStyle())
                }

                HStack(alignment: .top) {
                    TextField("Title of link", text: $referenceTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    TextField("Link", text: $referenceLink)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
            }
            Spacer()

        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

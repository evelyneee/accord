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
    @State public var showPFP = true
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
                        enablePFP = showPFP
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
                    .padding()
                    .toggleStyle(SwitchToggleStyle())
                }
                HStack(alignment: .top) {
                    TextField("Username", text: $usernameSettings)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        backendUsername = usernameSettings
                    }, label: {
                        Text("Set")
                            .fontWeight(.bold)
                    })
                }
                .padding()
                HStack(alignment: .top) {
                    TextField("Pronouns", text: $pronounSettings)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        pronouns = pronounSettings
                    }, label: {
                        Text("Set")
                            .fontWeight(.bold)
                    })
                }
                .padding()
                HStack {
                    Text("References")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    Button(action: {
                        if refLinks.count < 3 {
                            refLinks[referenceTitle] = referenceLink
                        }
                    }, label: {
                        Text("Set")
                    })
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
        .onAppear {
            usernameSettings = backendUsername
            showPFP = enablePFP
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

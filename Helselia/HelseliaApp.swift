//
//  HelseliaApp.swift
//  Helselia
//
//  Created by evelyn on 2020-11-24.
//

import SwiftUI

@main
struct HelseliaApp: App {
    @State private var modalIsPresented: Bool = false
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if token == nil {
                        modalIsPresented = true
                    }
                }
                .sheet(isPresented: $modalIsPresented) {
                    LoginView()
                        .frame(width: 450, height: 200)
                }
                .frame(minWidth: 500, minHeight: 300)
        }
    }
}

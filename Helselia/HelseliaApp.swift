//
//  HelseliaApp.swift
//  Helselia
//
//  Created by evelyn on 2020-11-24.
//

import SwiftUI

@main
struct HelseliaApp: App {
    @State private var modalIsPresented: Bool = true
    var body: some Scene {
        WindowGroup {
            ContentView()
//                .sheet(isPresented: $modalIsPresented) {
//                    LoginView()
//                        .frame(width: 450, height: 300)
//                }
                .frame(minWidth: 800, minHeight: 500)
        }
    }
}

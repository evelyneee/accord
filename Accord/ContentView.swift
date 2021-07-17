//
//  ContentView.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import SwiftUI

struct ContentView: View {
    @State public var selection: Int?
    @State var guilds: [[String:Any]] = []
    @State var socketOut: [String:Any] = [:]
    @State var channels: [Any] = []
    @State var status: statusIndicators?
    @State var modalIsPresented: Bool = false
    var body: some View {
        ServerListView(guilds: $guilds, full: $socketOut)
        .sheet(isPresented: $modalIsPresented) {
            LoginView()
                .onDisappear(perform: {
                    DispatchQueue.main.async {
                        NetworkHandling.shared?.request(url: "\(rootURL)/users/@me/guilds", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { success, array in
                            if success == true {
                                guilds = array ?? []
                            }
                        }
                    }
                })
                .frame(width: 450, height: 200)

        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("logged_in"))) { obj in
            WebSocketHandler.newMessage(opcode: 2) { success, array in
                 if !(array?.isEmpty ?? true) {
                     socketOut = array ?? [:]
                     guilds = array?["guilds"] as? [[String:Any]] ?? []
                     DispatchQueue.main.async {
                         NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                     }
                 }
            }
            DispatchQueue.main.async {
                NetworkHandling.shared?.requestData(url: "\(rootURL)/users/@me", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                    if (completion) {
                        guard let profile = try? JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String:Any] ?? [String:Any]() else { return }
                        user_id = profile["id"] as? String ?? ""
                        NetworkHandling.shared?.requestData(url: "https://cdn.discordapp.com/avatars/\(profile["id"] as? String ?? "")/\(profile["avatar"] as? String ?? "").png?size=256", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                        username = profile["username"] as? String ?? ""
                        discriminator = profile["discriminator"] as? String ?? ""
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SETUP_DONE"))) { notif in
            socketOut = [:]
        }
        .onAppear {
            if (AccordCoreVars.shared.token != "") {
                WebSocketHandler.newMessage(opcode: 2) { success, array in
                     if !(array?.isEmpty ?? false) {
                         socketOut = array ?? [:]
                         guilds = array?["guilds"] as? [[String:Any]] ?? []
                         DispatchQueue.main.async {
                             NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                         }
                     }
                }
                DispatchQueue.main.async {
                    NetworkHandling.shared?.requestData(url: "\(rootURL)/users/@me", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                        if (completion) {
                            guard let profile = try? JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String:Any] ?? [String:Any]() else { return }
                            user_id = profile["id"] as? String ?? ""
                            NetworkHandling.shared?.requestData(url: "https://cdn.discordapp.com/avatars/\(profile["id"] as? String ?? "")/\(profile["avatar"] as? String ?? "").png?size=256", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                            username = profile["username"] as? String ?? ""
                            discriminator = profile["discriminator"] as? String ?? ""
                        }
                    }

                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

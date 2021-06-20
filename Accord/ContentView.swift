//
//  ContentView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-24.
//

/*
 IMPORTANT
 guild-positions in socket
 private_channels for dms in socket
 */


import SwiftUI

struct ContentView: View {
    @State public var selection: Int?
    @State var clubs: [[String:Any]] = []
    @State var socketOut: [String:Any] = [:]
    @State var channels: [Any] = []
    @State var status: statusIndicators?
    @State var modalIsPresented: Bool = false {
        didSet {
            DispatchQueue.main.async {
                NetworkHandling.shared.request(url: "\(rootURL)/users/@me/\(clubsorguilds)", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                    if success == true {
                        clubs = array ?? []
                    }
                }
            }
        }
    }
    var body: some View {
        ServerListView(clubs: $clubs, full: $socketOut)
        .sheet(isPresented: $modalIsPresented) {
            LoginView()
                .onDisappear(perform: {
                    DispatchQueue.main.async {
                        NetworkHandling.shared.request(url: "\(rootURL)/users/@me/\(clubsorguilds)", token: token, json: false, type: .GET, bodyObject: [:]) { success, array in
                            if success == true {
                                clubs = array ?? []
                            }
                        }
                    }
                })
                .frame(width: 450, height: 200)

        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("logged_in"))) { obj in
            DispatchQueue.main.async {
                DispatchQueue.main.async {
                    WebSocketHandler.newMessage(opcode: 2) { success, array in
                         if !(array?.isEmpty ?? true) {
                             clubs = (array?["guilds"] ?? []) as! [[String : Any]]
                         }
                    }
                    net.requestData(url: "\(rootURL)/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                        if (completion) {
                            user_id = ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? ""
                            net.requestData(url: "https://cdn.discordapp.com/avatars/\(ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar", data: data)[safe: 0]  as? String ?? "").png?size=80", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                            username = ProfileManager.shared.getSelfProfile(key: "username", data: data)[safe: 0]  as? String ?? ""
                            discriminator = ProfileManager.shared.getSelfProfile(key: "discriminator", data: data)[safe: 0]  as? String ?? ""
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SETUP_DONE"))) { notif in
            socketOut = [:]
        }
        .onAppear {
            if (token != "") {
                DispatchQueue.main.async {
                    WebSocketHandler.newMessage(opcode: 2) { success, array in
                         if !(array?.isEmpty ?? true) {
                             socketOut = array ?? [:]
                             clubs = array?["guilds"] as? [[String:Any]] ?? []
                             DispatchQueue.main.async {
                                 NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                             }
                         }
                    }
                    net.requestData(url: "\(rootURL)/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                        if (completion) {
                            user_id = ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? ""
                            net.requestData(url: "https://cdn.discordapp.com/avatars/\(ProfileManager.shared.getSelfProfile(key: "id", data: data)[safe: 0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar", data: data)[safe: 0]  as? String ?? "").png?size=80", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                            username = ProfileManager.shared.getSelfProfile(key: "username", data: data)[safe: 0]  as? String ?? ""
                            discriminator = ProfileManager.shared.getSelfProfile(key: "discriminator", data: data)[safe: 0]  as? String ?? ""
                        }
                    }
                    
                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

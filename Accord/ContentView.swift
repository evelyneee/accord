//
//  ContentView.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import SwiftUI
import Combine

// Discord WebSocket
var wss: WebSocket!
let wssThread = DispatchQueue(label: "WebSocket Thread")

struct ContentView: View {
    @State public var selection: Int?
    @State var socketOut: GatewayD?
    @State var modalIsPresented: Bool = false
    var body: some View {
        Group {
            if modalIsPresented {
                LoginView()
            } else {
                ServerListView(full: $socketOut)
            }
        }
        .onAppear {
            if (AccordCoreVars.shared.token != "") {
                concurrentQueue.async {
                    let path = FileManager.default.urls(for: .cachesDirectory,
                                                        in: .userDomainMask)[0]
                                                        .appendingPathComponent("socketOut.json")

                    let data = try? Data(contentsOf: path) 
                    do {
                        let structure = try JSONDecoder().decode(GatewayStructure.self, from: data ?? Data())
                        socketOut = structure.d
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                        }
                    } catch {
                        print(error)
                    }
                    wss = WebSocket.init(url: URL(string: "wss://gateway.discord.gg?v=9&encoding=json"))
                    wss.ready() { d in
                        if let d = d {
                            socketOut = d
                            guard let user = socketOut?.user else { return }
                            AccordCoreVars.shared.user = user
                            user_id = user.id
                            if let pfp = user.avatar {
                                Request.image(url: URL(string: "https://cdn.discordapp.com/avatars/\(user.id)/\(pfp).png?size=128")) { image in if let image = image { avatar = image.tiffRepresentation ?? Data() } }
                            }
                            username = user.username
                            discriminator = user.discriminator
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                            }
                        }
                    }
                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

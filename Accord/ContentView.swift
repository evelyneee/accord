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

struct ContentView: View {
    @State public var selection: Int?
    @State var socketOut: GatewayD?
    @State var status: statusIndicators?
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
//                    let path = FileManager.default.urls(for: .cachesDirectory,
//                                                        in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
//                    print(path)
//                    let data = try? Data(contentsOf: path)
//                    if let data = data {
//                        guard let socketDecoded = try? JSONDecoder().decode(GatewayStructure.self, from: data) else { return }
//                        socketOut = socketDecoded.d
//                        DispatchQueue.main.async {
//                            NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
//                        }
//                    }
                    wss = WebSocket.init(url: URL(string: "wss://gateway.discord.gg?v=9&encoding=json"))
                    wss.ready() { d in
                        if let d = d {
                            socketOut = d
                            AccordCoreVars.shared.user = socketOut?.user
                            user_id = AccordCoreVars.shared.user?.id ?? ""
                            Networking<AnyDecodable>().image(url: URL(string: "https://cdn.discordapp.com/avatars/\(AccordCoreVars.shared.user?.id ?? "")/\(AccordCoreVars.shared.user?.avatar ?? "").png?size=128")) { image in if let image = image { avatar = image.tiffRepresentation ?? Data() } }
                            username = AccordCoreVars.shared.user?.username ?? ""
                            discriminator = AccordCoreVars.shared.user?.discriminator ?? ""
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

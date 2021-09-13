//
//  ContentView.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import SwiftUI

struct ContentView: View {
    @State public var selection: Int?
    @State var guilds = [Guild]()
    @State var socketOut: GatewayD?
    @State var channels: [Any] = []
    @State var status: statusIndicators?
    @State var modalIsPresented: Bool = false
    var body: some View {
        ServerListView(guilds: $guilds, full: $socketOut)
        .sheet(isPresented: $modalIsPresented) {
            LoginView()
                .onDisappear(perform: {
                    DispatchQueue.main.async {
                        NetworkHandling.shared.requestData(url: "\(rootURL)/users/@me/guilds", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { success, rawData in
                            if success == true {
                                guilds = try! JSONDecoder().decode([Guild].self, from: rawData!)
                            }
                        }
                    }
                })
                .frame(width: 450, height: 350)

        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("logged_in"))) { obj in
            WebSocketHandler.connect(opcode: 2) { success, array in
                 if let structure = array {
                     socketOut = structure
                     
                     guilds = socketOut!.guilds
                     DispatchQueue.main.async {
                         NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                     }
                 }
            }
        }
        .onAppear {
            if (AccordCoreVars.shared.token != "") {
                let path = FileManager.default.urls(for: .cachesDirectory,
                                                    in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                let data = try? Data(contentsOf: path)
                if let data = data {
                    guard let socketDecoded = try? JSONDecoder().decode(GatewayStructure.self, from: data) else { return }
                    socketOut = socketDecoded.d
                    guilds = socketDecoded.d.guilds
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                    }
                }
                WebSocketHandler.connect(opcode: 2) { success, array in
                     if let structure = array {
                         socketOut = structure
                         if socketOut?.guilds != guilds {
                             guilds = socketOut!.guilds
                             DispatchQueue.main.async {
                                 NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                             }
                         }

                     }
                }
                let userLoadQueue = DispatchQueue(label: "userLoadQueue", attributes: .concurrent)
                userLoadQueue.async {
                    NetworkHandling.shared.requestData(url: "\(rootURL)/users/@me", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                        if (completion) {
                            do {
                                AccordCoreVars.shared.user = try JSONDecoder().decode(User.self, from: data ?? Data())
                            } catch {
                            }
                            user_id = AccordCoreVars.shared.user?.id ?? ""
                            NetworkHandling.shared.requestData(url: "https://cdn.discordapp.com/avatars/\(AccordCoreVars.shared.user?.id ?? "")/\(AccordCoreVars.shared.user?.avatar ?? "").png?size=256", token: AccordCoreVars.shared.token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
                            username = AccordCoreVars.shared.user?.username ?? ""
                            discriminator = AccordCoreVars.shared.user?.discriminator ?? ""
                        }
                    }
                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

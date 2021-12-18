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

@available(macOS 11.0, *)
struct ContentView: View {
    @State public var selection: Int?
    @State var socketOut: GatewayD?
    @State var modalIsPresented: Bool = false
    @State var wsCancellable: AnyCancellable? = nil
    
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
                    guard wss == nil else { return }
                    guard let new = try? WebSocket.init(url: WebSocket.gatewayURL) else { return }
                    wss = new
                    wsCancellable = wss.ready()
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                print(error)
                                break
                            }
                        }, receiveValue: { d in
                            let user = d.user
                            AccordCoreVars.shared.user = user
                            user_id = user.id
                            if let pfp = user.avatar {
                                Request.fetch(url: URL(string: "https://cdn.discordapp.com/avatars/\(user.id)/\(pfp).png?size=80")) { avatar = $0 ?? Data(); _ = $1 }
                            }
                            username = user.username
                            discriminator = user.discriminator
                            socketOut = d
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                            }
                        })
                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

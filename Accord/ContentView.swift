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

struct AppIcon: View {
    var body: some View {
        Image(nsImage: NSApplication.shared.applicationIconImage)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    AppIcon().saturation(0.0)
                    Text("Connecting to Discord")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()
            }
            Spacer()
        }
    }
}

@available(macOS 11.0, *)
struct ContentView: View {
    @State public var selection: Int?
    @State var socketOut: GatewayD?
    @State var modalIsPresented: Bool = false
    @State var wsCancellable: AnyCancellable? = nil
    @State var loaded: Bool = false
    var body: some View {
        Group {
            if modalIsPresented {
                LoginView()
            } else if loaded {
                ServerListView(full: $socketOut)
            } else {
                LoadingView()
            }
        }
        .onAppear {
            if (AccordCoreVars.shared.token != "") {
                concurrentQueue.async {
                    guard wss == nil else { return }
                    guard let new = try? WebSocket.init(url: WebSocket.gatewayURL) else { return }
                    wss = new
                    wsCancellable = wss.ready()
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                loaded = true
                                break
                            case .failure(let error):
                                print(error)
                                let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                                let data = try? Data(contentsOf: path)
                                do {
                                    let structure = try JSONDecoder().decode(GatewayStructure.self, from: data ?? Data())
                                    socketOut = structure.d
                                    loaded = true
                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: Notification.Name(rawValue: "READY"), object: nil)
                                    }
                                } catch {
                                    print(error)
                                }
                                break
                            }
                        }, receiveValue: { d in
                            loaded = true
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

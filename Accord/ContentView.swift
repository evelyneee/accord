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

internal extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool,
                                          transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}

struct LoadingView: View {
    fileprivate static let greetings = [
        "Entering girlmode",
        "Stay dry.",
        "Gaslight. Gatekeep. Girlboss.",
        "eval deez nuts",
        "Not a car",
        "What the fuck is this Jailbreak drama y'all mad furries bro",
        "Now available on Rejail!"
    ]
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    AppIcon().saturation(0.0)
                    Text(LoadingView.greetings.randomElement() ?? "I fucked up")
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(5)
                    Text("Connecting...")
                        .foregroundColor(Color.secondary)
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
    @State var serverListView: ServerListView?
    var body: some View {
        Group {
            if modalIsPresented {
                LoginView()
            } else if !loaded {
                LoadingView()
            } else {
                serverListView
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
                                break
                            case .failure(let error):
                                print(error)
                                let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                                let data = try? Data(contentsOf: path)
                                do {
                                    let structure = try JSONDecoder().decode(GatewayStructure.self, from: data ?? Data())
                                    socketOut = structure.d
                                    self.serverListView = ServerListView(d: structure.d)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                        withAnimation {
                                            loaded = true
                                        }
                                    })
                                } catch {
                                    print(error)
                                }
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
                            self.serverListView = ServerListView(d: d)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                withAnimation {
                                    loaded = true
                                }
                            })
                        })
                }
            } else {
                modalIsPresented = true
            }
        }
    }
}

//
//  ContentView.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import Combine
import SwiftUI

struct ContentView: View {
    @State var modalIsPresented: Bool = false
    @State var wsCancellable = Set<AnyCancellable>()
    @Binding var loaded: Bool
    @State var serverListView: ServerListView?

    enum LoadErrors: Error {
        case alreadyLoaded
        case offline
    }

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
            concurrentQueue.async {
                guard AccordCoreVars.token != "" else { modalIsPresented = true; return }
                do {
                    guard wss == nil else {
                        throw LoadErrors.alreadyLoaded
                    }
                    guard NetworkCore.shared.connected else {
                        throw LoadErrors.offline
                    }
                    let new = try Gateway(url: Gateway.gatewayURL)
                    new.ready()
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case let .failure(error):
                                print(error)
                            }
                        }) { d in
                            AccordCoreVars.user = d.user
                            user_id = d.user.id
                            if let pfp = d.user.avatar {
                                Request.fetch(url: URL(string: "https://cdn.discordapp.com/avatars/\(d.user.id)/\(pfp).png?size=80")) { completion in
                                    switch completion {
                                    case .success(let data):
                                        avatar = data
                                    case .failure(let error):
                                        print(error)
                                    }
                                }
                            }
                            username = d.user.username
                            discriminator = d.user.discriminator
                            self.serverListView = ServerListView(full: d)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    loaded = true
                                }
                            }
                        }
                        .store(in: &wsCancellable)
                    print("init")
                    wss = new
                } catch {
                    print(error)
                    let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                    do {
                        let data = try Data(contentsOf: path)
                        let structure = try JSONDecoder().decode(GatewayStructure.self, from: data)
                        self.serverListView = ServerListView(full: structure.d)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                loaded = true
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onDisappear {
            print("uh bye")
            Emotes.emotes.removeAll()
        }
    }
}

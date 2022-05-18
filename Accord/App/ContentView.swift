//
//  ContentView.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import Combine
import SwiftUI

extension EnvironmentValues {
    var user: User {
        get { self[UserKey.self] }
        set { self[UserKey.self] = newValue }
    }
}

private struct UserKey: EnvironmentKey {
    static let defaultValue = AccordCoreVars.user!
}

struct ContentView: View {
    @State var modalIsPresented: Bool = false
    @State var wsCancellable = Set<AnyCancellable>()
    @Binding var loaded: Bool
    @State var serverListView: ServerListView?

    enum LoadErrors: Error {
        case alreadyLoaded
        case offline
    }

    @ViewBuilder
    var body: some View {
        if modalIsPresented {
            LoginView()
        } else if !loaded {
            LoadingView()
                .onAppear {
                    concurrentQueue.async {
                        guard AccordCoreVars.token != "" else { modalIsPresented = true; return }
                        do {
                            guard serverListView == nil else {
                                loaded = true
                                return
                            }
                            guard wss == nil else {
                                throw LoadErrors.alreadyLoaded
                            }
                            guard NetworkCore.shared.connected else {
                                throw LoadErrors.offline
                            }
                            print("hiiiii")
                            let new = try Gateway(
                                url: Gateway.gatewayURL,
                                compress: UserDefaults.standard.value(forKey: "CompressGateway") as? Bool ?? true
                            )
                            new.ready()
                                .sink(receiveCompletion: { completion in
                                    switch completion {
                                    case .finished: break
                                    case let .failure(error):
                                        failedToConnect(error)
                                    }
                                }) { d in
                                    AccordCoreVars.user = d.user
                                    user_id = d.user.id
                                    if let pfp = d.user.avatar {
                                        Request.fetch(url: URL(string: cdnURL + "/avatars/\(d.user.id)/\(pfp).png?size=80")) { completion in
                                            switch completion {
                                            case let .success(data):
                                                avatar = data
                                            case let .failure(error):
                                                print(error)
                                            }
                                        }
                                    }
                                    let view = ServerListView(d)
                                    DispatchQueue.main.async {
                                        self.serverListView = view
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation {
                                            loaded = true
                                        }
                                    }
                                }
                                .store(in: &wsCancellable)
                            wss = new
                        } catch {
                            failedToConnect(error)
                        }
                    }
                }
        } else if let serverListView = serverListView {
            serverListView
        } else {
            Text("Why are we here??")
                .padding(200)
        }
    }
    
    func failedToConnect(_ error: Error) {
        print(error)
        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
        do {
            let data = try Data(contentsOf: path)
            let structure = try JSONDecoder().decode(GatewayStructure.self, from: data)
            DispatchQueue.main.async {
                self.serverListView = ServerListView(structure.d)
                AccordCoreVars.user = structure.d.user
            }
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

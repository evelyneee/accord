//
//  ContentView.swift
//  Accord
//
//  Created by evelyn on 2020-11-24.
//

import AppKit
import Combine
import SwiftUI

extension EnvironmentValues {
    var user: User {
        get { self[UserKey.self] }
        set { self[UserKey.self] = newValue }
    }
}

private struct UserKey: EnvironmentKey {
    static let defaultValue = Globals.user!
}

struct ContentView: View {
    
    @State var modalIsPresented: Bool = false
    @State var wsCancellable = Set<AnyCancellable>()
    @Binding var loaded: Bool
    
    @MainActor @State
    var serverListView: ServerListView?

    enum LoadErrors: Error {
        case alreadyLoaded
        case offline
    }
    
    @EnvironmentObject
    var appModel: AppGlobals

    @ViewBuilder
    var body: some View {
        if modalIsPresented {
            LoginView()
        } else if !loaded {
            LoadingView()
                .onAppear {
                    concurrentQueue.async {
                        guard !Globals.token.isEmpty else { modalIsPresented = true; return }
                        do {
                            guard serverListView == nil else {
                                loaded = true
                                return
                            }
                            guard wss == nil else {
                                throw LoadErrors.alreadyLoaded
                            }
                            guard reachability?.connected == true else {
                                throw LoadErrors.offline
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                NSApp.keyWindow?.identifier = NSUserInterfaceItemIdentifier("AccordMainWindow")
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
                                    Globals.user = d.user
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

//                            concurrentQueue.asyncAfter(deadline: .now() + 5, execute: {
//                                try? wss.updateVoiceState(
//                                    guildID: "825437365027864578",
//                                    channelID: "971218660146425876",
//                                    deafened: true,
//                                    muted: true,
//                                    streaming: false
//                                )
//                            })
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
                Globals.user = structure.d.user
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

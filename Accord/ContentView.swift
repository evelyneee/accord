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

struct TiltAnimation: ViewModifier {
    @State var rotated: Bool = false
    @State var timer: Timer?
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotated ? 10 : -10))
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                    withAnimation(Animation.spring()) {
                        rotated.toggle()
                    }
                }
            }
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

    fileprivate static let greetings: [Text] = [
        Text("Entering girlmode"),
        Text("Stay dry"),
        Text("Gaslight. Gatekeep. Girlboss.").italic(),
        Text("eval deez nuts"),
        Text("Not a car"),
        Text("Ratio + Civic better"),
        Text("Now available on Rejail!"),
        Text("The more mature, hot older sister."),
        Text("Send your best hints to ") + Text("evln#0001").font(Font.system(.title2, design: .monospaced)),
        Text("Never gonna give you up, never gonna use electron"),
        Text("Tell ur oomfies")
    ]

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Image(nsImage: NSApp.applicationIconImage)
                        .saturation(0.0).modifier(TiltAnimation())
                    LoadingView.greetings.randomElement()!
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

struct ContentView: View {
    @State var modalIsPresented: Bool = false
    @State var wsCancellable = Set<AnyCancellable>()
    @Binding var loaded: Bool
    @State var serverListView: ServerListView?

    enum LoadErrors: Error {
        case alreadyLoaded
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
                guard AccordCoreVars.shared.token != "" else { modalIsPresented = true; return }
                do {
                    guard wss == nil else {
                        throw LoadErrors.alreadyLoaded
                    }
                    let new = try WebSocket.init(url: WebSocket.gatewayURL)
                    print("init")
                    wss = new
                    wss.ready()
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                print(error)
                                break
                            }
                        }, receiveValue: { d in
                            weak var user = d?.user
                            AccordCoreVars.shared.user = user
                            user_id = user?.id ?? ""
                            if let pfp = user?.avatar {
                                Request.fetch(url: URL(string: "https://cdn.discordapp.com/avatars/\(user?.id ?? "")/\(pfp).png?size=80")) { avatar = $0 ?? Data(); _ = $1 }
                            }
                            username = user?.username ?? ""
                            discriminator = user?.discriminator ?? ""
                            self.serverListView = ServerListView(full: d)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                withAnimation {
                                    loaded = true
                                }
                            })
                        })
                        .store(in: &wsCancellable)
                } catch {
                    print(error)
                    let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("socketOut.json")
                    do {
                        let data = try Data(contentsOf: path)
                        let structure = try JSONDecoder().decode(GatewayStructure.self, from: data)
                        self.serverListView = ServerListView(full: structure.d)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            withAnimation {
                                loaded = true
                            }
                        })
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}

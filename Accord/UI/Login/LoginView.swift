//
//  LoginView.swift
//  Accord
//
//  Created by Évelyne on 2021-05-23.
//

import SwiftUI
import WebKit

enum LoginState {
    case initial
    case captcha
    case twoFactor
}

enum DiscordLoginErrors: Error {
    case invalidForm
    case missingFields
}

extension NSApplication {
    func restart() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LoggedIn"), object: nil, userInfo: [:])
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        exit(EXIT_SUCCESS)
    }
}

struct LoginViewDataModel {
    var email: String = ""
    var password: String = ""
    var twoFactor: String = ""
    var token: String = ""
    var captcha: Bool = false
    var captchaVCKey: String?
    var captchaPayload: String?
    var proxyIP: String = ""
    var proxyPort: String = ""
    var state: LoginState = .initial
    var notification: [String: Any] = [:]
    var error: String?
}

struct LoginView: View {
    @StateObject var viewModel: LoginViewViewModel = .init()
    @State var loginViewDataModel: LoginViewDataModel = .init()

    var body: some View {
        VStack {
            switch viewModel.state {
            case .initial:
                initialView
            case .captcha:
                captchaView
            case .twoFactor:
                twoFactorView
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Captcha"))) { notification in
            self.viewModel.state = .twoFactor
            self.loginViewDataModel.notification = notification.userInfo as? [String: Any] ?? [:]
            print(notification)
        }
        .padding()
    }

    @ViewBuilder
    private var initialViewTopView: some View {
        Text("Welcome to Accord")
            .font(.title)
            .fontWeight(.bold)
            .padding(.bottom, 5)
            .padding(.top)

        Text("Choose how you want to login")
            .foregroundColor(Color.secondary)
            .padding(.bottom)
    }

    @ViewBuilder
    private var initialViewFields: some View {
        TextField("Email", text: $loginViewDataModel.email)
        SecureField("Password", text: $loginViewDataModel.password)
        TextField("Token (optional)", text: $loginViewDataModel.token)
        TextField("Proxy IP (optional)", text: $loginViewDataModel.proxyIP)
        TextField("Proxy Port (optional)", text: $loginViewDataModel.proxyPort)
    }

    @ViewBuilder
    private var errorView: some View {
        if let error = viewModel.loginError {
            switch error {
            case DiscordLoginErrors.invalidForm:
                Text("Wrong username/password")
            default:
                EmptyView()
            }
        }
    }

    private var bottomView: some View {
        HStack {
            Spacer()
            Button("Cancel") {
                exit(EXIT_SUCCESS)
            }
            .accentColor(.clear)
            .controlSize(.large)
            Button("Login") { [weak viewModel] in
                viewModel?.loginError = nil
                UserDefaults.standard.set(self.loginViewDataModel.proxyIP, forKey: "proxyIP")
                UserDefaults.standard.set(self.loginViewDataModel.proxyPort, forKey: "proxyPort")
                if !loginViewDataModel.token.isEmpty {
                    AccordApp.tokenUpdate.send(loginViewDataModel.token)
                } else {
                    try? viewModel?.login(loginViewDataModel.email, loginViewDataModel.password, loginViewDataModel.twoFactor)
                }
                print("logging in")
            }
            .keyboardShortcut(.return)
            .controlSize(.large)
        }
        .padding(.top, 5)
    }

    private var AccordIconView: some View {
        VStack {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 150)
                .padding()
        }
    }

    private var AccordTabView: some View {
        TabView {
            Form {
                TextField("Email:", text: $loginViewDataModel.email)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password:", text: $loginViewDataModel.password)
                    .textFieldStyle(.roundedBorder)
            }.tabItem {
                Text("Email and Password")
            }
            .frame(maxHeight: 200)
            .padding()
            Form {
                TextField("Token:", text: $loginViewDataModel.token)
                    .textFieldStyle(.roundedBorder)
            }.tabItem {
                Text("Token")
            }
            .padding()
        }
    }

    private var initialView: some View {
        VStack {
            HStack {
                AccordIconView
                    .padding()
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome!")
                                .font(.system(size: 50))
                            Text("You'll need to log in to continue.")
                                .font(.title)
                        }
                        Spacer()
                    }
                    .padding([.bottom], 20)
                    AccordTabView
                }
            }
            .padding()
            HStack {
                Spacer()
                bottomView
            }
            .padding([.trailing])
        }
        .padding()
    }

    private var twoFactorView: some View {
        VStack {
            Spacer()
            Text("Enter your two-factor code here.")
                .font(.title3)
                .fontWeight(.medium)

            SecureField("Six-digit MFA code", text: $loginViewDataModel.twoFactor)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)

            Spacer()

            HStack {
                Spacer()
                Button("Login") {
                    if let ticket = viewModel.ticket {
                        Request.fetch(LoginResponse.self, url: URL(string: "\(rootURL)/auth/mfa/totp"), headers: Headers(
                            token: Globals.token,
                            bodyObject: ["code": loginViewDataModel.twoFactor, "ticket": ticket],
                            type: .POST,
                            discordHeaders: true,
                            json: true
                        )) { completion in
                            switch completion {
                            case let .success(value):
                                if let token = value.token {
                                    DispatchQueue.main.async {
                                        AccordApp.tokenUpdate.send(token)
                                    }
                                    self.loginViewDataModel.captcha = false
                                }
                            case let .failure(error):
                                print(error)
                            }
                        }
                        return
                    }
                    self.loginViewDataModel.captchaPayload = loginViewDataModel.notification["key"] as? String ?? ""
                    Request.fetch(LoginResponse.self, url: URL(string: "\(rootURL)/auth/login"), headers: Headers(
                        bodyObject: [
                            "email": loginViewDataModel.email,
                            "password": loginViewDataModel.password,
                            "captcha_key": loginViewDataModel.captchaPayload ?? "",
                        ],
                        type: .POST,
                        discordHeaders: true,
                        json: true
                    )) { completion in
                        switch completion {
                        case let .success(response):
                            if let token = response.token {
                                DispatchQueue.main.async {
                                    AccordApp.tokenUpdate.send(token)
                                }
                                self.loginViewDataModel.captcha = false
                            }
                            if let ticket = response.ticket {
                                Request.fetch(LoginResponse.self, url: URL(string: "\(rootURL)/auth/mfa/totp"), headers: Headers(
                                    contentType: "application/json",
                                    token: Globals.token,
                                    bodyObject: ["code": loginViewDataModel.twoFactor, "ticket": ticket],
                                    type: .POST,
                                    discordHeaders: true,
                                    json: true
                                )) { completion in
                                    switch completion {
                                    case let .success(response) where response.token != nil:
                                        DispatchQueue.main.async {
                                            AccordApp.tokenUpdate.send(response.token)
                                        }
                                        self.loginViewDataModel.captcha = false
                                    case let .failure(error):
                                        print(error)
                                    default: break
                                    }
                                }
                            }
                        case let .failure(error):
                            print(error)
                        }
                    }
                }
                .controlSize(.large)
            }
        }
    }

    private var captchaView: some View {
        CaptchaViewControllerSwiftUI(token: captchaPublicKey)
            .transition(AnyTransition.moveAway)
    }
}

final class LoginViewViewModel: ObservableObject {
    @Published var state: LoginState = .initial
    @Published var captcha: Bool = false
    @Published var captchaVCKey: String?
    @Published var captchaPayload: String?
    @Published var ticket: String? = nil
    @Published var loginError: Error? = nil

    init() {}

    func login(_ email: String, _ password: String, _: String) throws {
        Request.fetch(LoginResponse.self, url: URL(string: "\(rootURL)/auth/login"), headers: Headers(
            bodyObject: [
                "email": email,
                "password": password,
            ],
            type: .POST,
            discordHeaders: true,
            json: true
        )) { [weak self] completion in
            DispatchQueue.main.async {
                switch completion {
                case let .success(response):
                    if let checktoken = response.token {
                        AccordApp.tokenUpdate.send(checktoken)
                    } else {
                        if let captchaKey = response.captcha_sitekey {
                            self?.captchaVCKey = captchaKey
                            captchaPublicKey = captchaKey
                            self?.state = .captcha
                        } else if let ticket = response.ticket {
                            self?.state = .twoFactor
                            self?.ticket = ticket
                            dprint("[Login debug] Got ticket")
                        }
                    }
                    if let error = response.message {
                        switch error {
                        case "Invalid Form Body":
                            self?.loginError = DiscordLoginErrors.invalidForm
                        default:
                            self?.loginError = DiscordLoginErrors.invalidForm
                        }
                    }
                case let .failure(error):
                    print(error)
                    self?.loginError = error
                }
            }
        }
    }
}

extension AnyTransition {
    static var moveAway: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    }
}

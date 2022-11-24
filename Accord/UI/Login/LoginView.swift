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
    case error(String)
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
            try? self.viewModel.login(self.loginViewDataModel.email, self.loginViewDataModel.password, notification.userInfo?["key"] as? String ?? "")
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
            case DiscordLoginErrors.error(let str):
                if str == "Invalid Form Body" {
                    Text("Error: ")+Text("Invalid form body, check your mailbox for verifications")
                } else {
                    Text("Error: ")+Text(str).foregroundColor(.red)
                }
            default:
                EmptyView()
            }
        }
    }

    private var bottomView: some View {
        HStack {
            Spacer()
            if viewModel.loggingIn {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.horizontal, 3)
            }
            Button("Cancel") {
                exit(EXIT_SUCCESS)
            }
            .accentColor(.clear)
            .controlSize(.large)
            Button("Login") { [weak viewModel] in
                login(viewModel)
            }
            .keyboardShortcut(.return)
            .controlSize(.large)
        }
        .padding(.top, 5)
    }
    
    private func login(_ viewModel: LoginViewViewModel?) {
        viewModel?.loggingIn = true
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
            }
            .tabItem {
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
        .onSubmit { [weak viewModel] in
            login(viewModel)
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
                    errorView
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
                .onSubmit {
                    mfaLogin()
                }

            Spacer()

            HStack {
                Spacer()
                if viewModel.mfaLoggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.horizontal, 3)
                }
                Button("Login") {
                    mfaLogin()
                }
                .controlSize(.large)
            }
        }
    }

    private var captchaView: some View {
        CaptchaViewControllerSwiftUI(token: captchaPublicKey)
            .transition(AnyTransition.moveAway)
    }
    
    private func mfaLogin() {
        viewModel.mfaLoggingIn = true
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
}

final class LoginViewViewModel: ObservableObject {
    @Published var state: LoginState = .initial
    @Published var captcha: Bool = false
    @Published var captchaVCKey: String?
    @Published var captchaPayload: String?
    @Published var ticket: String? = nil
    @Published var loginError: Error? = nil
    @Published var loggingIn: Bool = false
    @Published var mfaLoggingIn: Bool = false

    init() {}

    func login(_ email: String, _ password: String, _ captcha: String) throws {
        Request.fetch(LoginResponse.self, url: URL(string: "\(rootURL)/auth/login"), headers: Headers(
            bodyObject: [
                "login": email,
                "password": password,
                "captcha_key":captcha
            ].compactMapValues { $0 },
            type: .POST,
            discordHeaders: true,
            json: true
        )) { [weak self] completion in
            DispatchQueue.main.async {
                switch completion {
                case let .success(response):
                    dump(response)
                    if let error = response.message {
                        print(error)
                        self?.loginError = DiscordLoginErrors.error(error)
                        self?.state = .initial
                        return
                    }
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

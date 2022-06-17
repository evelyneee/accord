//
//  LoginView.swift
//  Accord
//
//  Created by Évelyne on 2021-05-23.
//

import SwiftUI
import WebKit

public var captchaPublicKey: String = "error"

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
                    KeychainManager.save(key: keychainItemName, data: loginViewDataModel.token.data(using: String.Encoding.utf8) ?? Data())
                    Globals.token = String(decoding: KeychainManager.load(key: keychainItemName) ?? Data(), as: UTF8.self)
                    NSApplication.shared.restart()
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
                            userAgent: discordUserAgent,
                            token: Globals.token,
                            bodyObject: ["code": loginViewDataModel.twoFactor, "ticket": ticket],
                            type: .POST,
                            discordHeaders: true,
                            json: true
                        )) { completion in
                            switch completion {
                            case let .success(value):
                                if let token = value.token {
                                    KeychainManager.save(key: keychainItemName, data: token.data(using: .utf8) ?? Data())
                                    Globals.token = String(decoding: KeychainManager.load(key: keychainItemName) ?? Data(), as: UTF8.self)
                                    self.loginViewDataModel.captcha = false
                                    NSApplication.shared.restart()
                                }
                            case let .failure(error):
                                print(error)
                            }
                        }
                        return
                    }
                    self.loginViewDataModel.captchaPayload = loginViewDataModel.notification["key"] as? String ?? ""
                    Request.fetch(LoginResponse.self, url: URL(string: "\(rootURL)/auth/login"), headers: Headers(
                        userAgent: discordUserAgent,
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
                                KeychainManager.save(key: keychainItemName, data: token.data(using: String.Encoding.utf8) ?? Data())
                                Globals.token = String(decoding: KeychainManager.load(key: keychainItemName) ?? Data(), as: UTF8.self)
                                self.loginViewDataModel.captcha = false
                                NSApplication.shared.restart()
                            }
                            if let ticket = response.ticket {
                                Request.fetch(LoginResponse.self, url: URL(string: "\(rootURL)/auth/mfa/totp"), headers: Headers(
                                    userAgent: discordUserAgent,
                                    contentType: "application/json",
                                    token: Globals.token,
                                    bodyObject: ["code": loginViewDataModel.twoFactor, "ticket": ticket],
                                    type: .POST,
                                    discordHeaders: true,
                                    json: true
                                )) { completion in
                                    switch completion {
                                    case let .success(response):
                                        if let token = response.token {
                                            KeychainManager.save(key: keychainItemName, data: token.data(using: String.Encoding.utf8) ?? Data())
                                            Globals.token = String(decoding: KeychainManager.load(key: keychainItemName) ?? Data(), as: UTF8.self)
                                            self.loginViewDataModel.captcha = false
                                            NSApplication.shared.restart()
                                        }
                                    case let .failure(error):
                                        print(error)
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
            userAgent: discordUserAgent,
            bodyObject: [
                "email": email,
                "password": password,
            ],
            type: .POST,
            discordHeaders: true,
            json: true
        )) { [weak self] completion in
            switch completion {
            case let .success(response):
                if let checktoken = response.token {
                    KeychainManager.save(key: keychainItemName, data: checktoken.data(using: String.Encoding.utf8) ?? Data())
                    Globals.token = String(decoding: KeychainManager.load(key: keychainItemName) ?? Data(), as: UTF8.self)
                    let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
                    let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
                    let task = Process()
                    task.launchPath = "/usr/bin/open"
                    task.arguments = [path]
                    task.launch()
                    exit(EXIT_SUCCESS)
                } else {
                    if let captchaKey = response.captcha_sitekey {
                        DispatchQueue.main.async {
                            self?.captchaVCKey = captchaKey
                            captchaPublicKey = captchaKey
                            self?.state = .captcha
                        }
                    } else if let ticket = response.ticket {
                        self?.state = .twoFactor
                        self?.ticket = ticket
                        print("[Login debug] Got ticket")
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

extension AnyTransition {
    static var moveAway: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    }
}

struct CaptchaViewControllerSwiftUI: NSViewRepresentable {
    init(token: String) {
        siteKey = token
        print(token, siteKey)
    }

    let siteKey: String

    func makeNSView(context _: Context) -> WKWebView {
        var webView = WKWebView()
        let webConfiguration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        let scriptHandler = ScriptHandler()
        contentController.add(scriptHandler, name: "hCaptcha")
        webConfiguration.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: webConfiguration)

        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: webView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
        ])
        if siteKey != "" {
            webView.loadHTMLString(generateHTML, baseURL: URL(string: "https://discord.com")!)
        }
        return webView
    }

    func updateNSView(_: WKWebView, context _: Context) {}
}

final class ScriptHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "Captcha"), object: nil, userInfo: ["key": message.body as! String])
        }
    }
}

extension CaptchaViewControllerSwiftUI {
    private var generateHTML: String {
        """
        <html>
            <head>
            <title>Discord Login Captcha</title>
            <script src="https://hcaptcha.com/1/api.js?onload=renderCaptcha&render=explicit" async defer></script>
            <script type="text/javascript">
                function post(value) {
                    window.webkit.messageHandlers.hCaptcha.postMessage(value);
                }
                function onSubmit(token) {
                    var hcaptchaVal = document.getElementsByName("h-captcha-response")[0].value;
                    window.webkit.messageHandlers.hCaptcha.postMessage(hcaptchaVal);
                }
                function renderCaptcha() {
                    var options = { sitekey: "${sitekey}", callback: "onSubmit", size: "compact" };
                    if (window?.matchMedia("(prefers-color-scheme: dark)")?.matches) {
                        options["theme"] = "dark";
                    }
                    hcaptcha.render("captcha", options);
                }
            </script>
            <style>
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #2f2f2f;
                    }
                }
                @media (prefers-color-scheme: light) {
                    body {
                        background-color: #c0c0c0;
                    }
                }
                .center {
                    margin: 0;
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    -ms-transform: translate(-50%, -50%);
                    transform: translate(-50%, -50%);
                }
                .h-captcha {
                    transform-origin: center;
                    -webkit-transform-origin: center;
                    display: inline-block;
                }
            </style>
            </head>
            <body>
                <div class="center">
                      <div id="captcha" class="h-captcha" data-sitekey="${sitekey}" data-callback="onSubmit"></div>
                </div>
                  <br />
            </body>
        </html>
        """.replacingOccurrences(of: "${sitekey}", with: siteKey)
    }
}

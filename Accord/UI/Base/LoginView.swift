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
    case twofactor
}

enum DiscordLoginErrors: Error {
    case invalidForm
    case missingFields
}

struct SwappedLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension NSApplication {
    func restart() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        exit(EXIT_SUCCESS)
    }
}

struct LoginView: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var twofactor: String = ""
    @State var token: String = ""
    @State var captcha: Bool = false
    @State var captchaVCKey: String?
    @State var captchaPayload: String?
    @State var proxyIP: String = ""
    @State var proxyPort: String = ""
    @State var state: LoginState = .initial
    @State var notif: [String:Any] = [:]
    @State var error: String? = nil
    @ObservedObject var viewModel = LoginViewViewModel()
    var body: some View {
        VStack {
            switch viewModel.state {
            case .initial:
                VStack {
                    Text("Welcome to Accord")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 5)
                        .padding(.top)
                    Text("Choose how you want to login")
                        .foregroundColor(Color.secondary)
                        .padding(.bottom)
                    TextField("Email", text: $email)
                    TextField("Password", text: $password)
                    TextField("Token (optional)", text: $token)
                    TextField("Proxy IP (optional)", text: $proxyIP)
                    TextField("Proxy Port (optional)", text: $proxyPort)
                    if let error = error {
                        Text(error)
                            .foregroundColor(Color.red)
                            .font(.subheadline)
                    }
                    HStack {
                        Button(action: {
                            exit(EXIT_SUCCESS)
                        }, label: {
                            HStack {
                                Text("Cancel")
                                    .padding(.top)
                            }
                        })
                        Spacer()
                        Button(action: {
                            UserDefaults.standard.set(self.proxyIP, forKey: "proxyIP")
                            UserDefaults.standard.set(self.proxyPort, forKey: "proxyPort")
                            if token != "" {
                                _ = KeychainManager.save(key: "me.evelyn.accord.token", data: token.data(using: String.Encoding.utf8) ?? Data())
                                AccordCoreVars.shared.token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
                            } else {
                                do {
                                    try viewModel.login(email, password, twofactor)
                                } catch {
                                    switch error {
                                    case DiscordLoginErrors.invalidForm:
                                        self.error = "Invalid login and/or password"
                                    default:
                                        self.error = "An error occured"
                                    }
                                }
                            }
                            print("[Accord] logging in")
                        }) {
                            Label("Login", systemImage: "arrowtriangle.right.fill")
                                .labelStyle(SwappedLabel())
                        }
                    }
                    .padding(.top, 5)
                }
                .transition(AnyTransition.moveAway)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            case .captcha:
                CaptchaViewControllerSwiftUI(token: captchaPublicKey)
                    .transition(AnyTransition.moveAway)
            case .twofactor:
                VStack {
                    Text("Enter your two-factor code here.")
                    TextField("2fa code", text: $twofactor)
                    Button("Login") {
                        self.captchaPayload = notif["key"] as? String ?? ""
                        Request.fetch(LoginResponse.self, url: URL(string: "https://discord.com/api/v9/auth/login"), headers: Headers(
                            userAgent: discordUserAgent,
                            contentType: "application/json",
                            bodyObject: [
                                "email": email,
                                "password": password,
                                "captcha_key": captchaPayload ?? ""
                            ],
                            type: .POST,
                            discordHeaders: true,
                            json: true
                        )) { response, error in
                            if let token = response?.token {
                                _ = KeychainManager.save(key: "me.evelyn.accord.token", data: token.data(using: String.Encoding.utf8) ?? Data())
                                AccordCoreVars.shared.token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
                                self.captcha = false
                                let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
                                let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
                                let task = Process()
                                task.launchPath = "/usr/bin/open"
                                task.arguments = [path]
                                task.launch()
                                exit(EXIT_SUCCESS)
                            }
                            if let response = response, let ticket = response.ticket {
                                Request.fetch(LoginResponse.self, url: URL(string: "https://discord.com/api/v9/auth/mfa/totp"), headers: Headers(userAgent: discordUserAgent,
                                    contentType: "application/json",
                                    token: AccordCoreVars.shared.token,
                                    bodyObject: ["code": twofactor, "ticket": ticket],
                                    type: .POST,
                                    discordHeaders: true,
                                    json: true
                                )) { value, error in
                                    if let token = value?.token {
                                        _ = KeychainManager.save(key: "me.evelyn.accord.token", data: token.data(using: String.Encoding.utf8) ?? Data())
                                        AccordCoreVars.shared.token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
                                        self.captcha = false
                                        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
                                        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
                                        let task = Process()
                                        task.launchPath = "/usr/bin/open"
                                        task.arguments = [path]
                                        task.launch()
                                        exit(EXIT_SUCCESS)
                                    }
                                }
                            }
                        }
                    }
                }
                .transition(AnyTransition.moveAway)
            }

        }
        .frame(minHeight: 250)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Captcha"))) { notif in
            self.viewModel.state = .twofactor
            self.notif = notif.userInfo as? [String:Any] ?? [:]
            print(notif)
        }
        .padding()
    }
}

final class LoginViewViewModel: ObservableObject {
    
    @Published var state: LoginState = .initial
    @Published var captcha: Bool = false
    @Published var captchaVCKey: String?
    @Published var captchaPayload: String?
    
    init() {
        
    }
    
    func login(_ email: String, _ password: String, _ twofactor: String) throws {
        var loginError: Error? = nil
        Request.fetch(LoginResponse.self, url: URL(string: "https://discord.com/api/v9/auth/login"), headers: Headers(
            userAgent: discordUserAgent,
            contentType: "application/json",
            bodyObject: [
                "email": email,
                "password": password
            ],
            type: .POST,
            discordHeaders: true,
            json: true
        )) { response, error in
            if let response = response {
                if let error = response.message {
                    switch error {
                    case "Invalid Form Body":
                        loginError = DiscordLoginErrors.invalidForm
                    default:
                        loginError = DiscordLoginErrors.invalidForm
                    }
                }
                if let checktoken = response.token {
                    _ = KeychainManager.save(key: "me.evelyn.accord.token", data: checktoken.data(using: String.Encoding.utf8) ?? Data())
                    AccordCoreVars.shared.token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
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
                            self.captchaVCKey = captchaKey
                            captchaPublicKey = self.captchaVCKey!
                            self.state = .captcha
                        }
                    } else if let ticket = response.ticket {
                        print("[Login debug] Got ticket")
                        Request.fetch(LoginResponse.self, url: URL(string: "https://discord.com/api/v9/auth/mfa/totp"), headers: Headers(userAgent: discordUserAgent,
                            contentType: "application/json",
                            token: AccordCoreVars.shared.token,
                            bodyObject: ["code": twofactor, "ticket": ticket],
                            type: .POST,
                            discordHeaders: true,
                            json: true
                        )) { value, error in
                            if let token = value?.token {
                                _ = KeychainManager.save(key: "me.evelyn.accord.token", data: token.data(using: String.Encoding.utf8) ?? Data())
                                AccordCoreVars.shared.token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
                                self.captcha = false
                                let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
                                let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
                                let task = Process()
                                task.launchPath = "/usr/bin/open"
                                task.arguments = [path]
                                task.launch()
                                exit(EXIT_SUCCESS)
                            } else if let error = error {
                                releaseModePrint(error)
                            }
                        }
                    }
                }
            } else if let error = error {
                releaseModePrint(error)
                loginError = error
            }
        }
        if let loginError = loginError {
            throw loginError
        }
    }
}

extension AnyTransition {
    static var moveAway: AnyTransition {
        return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    }
}

struct CaptchaViewControllerSwiftUI: NSViewRepresentable {
    
    init(token: String) {
        self.siteKey = token
        print(token, siteKey)
    }
    let siteKey: String

    func makeNSView(context: Context) -> WKWebView {

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
            webView.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        ])
        if siteKey != "" {
            webView.loadHTMLString(generateHTML, baseURL: URL(string: "https://discord.com")!)
        }
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
    
    }
    
    typealias NSViewType = WKWebView
}

final class ScriptHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "Captcha"), object: nil, userInfo: ["key":message.body as! String])
        }
    }
}

/*
 - extracted from Discord iOS v100
 
 function documentReady() {
   var PAGE_BG_COLOR = RECAPTCHA_THEME == 'dark' ? '#222' : '#fff';
   document.body.style.backgroundColor = PAGE_BG_COLOR;
   showCaptcha(document.body.firstElementChild);
 }

 function showCaptcha(el) {
   try {
     grecaptcha.render(el, {
       sitekey: RECAPTCHA_SITE_KEY,
       theme: RECAPTCHA_THEME,
       callback: captchaSolved,
       'expired-callback': captchaExpired,
     });

     window.webkit.messageHandlers.reCaptcha.postMessage(['didLoad']);
   } catch (_) {
     window.setTimeout(function() {
       showCaptcha(el);
     }, 50);
   }
 }

 function captchaSolved(response) {
   window.webkit.messageHandlers.reCaptcha.postMessage(['didSolve', response]);
 }

 function captchaExpired(response) {
   window.webkit.messageHandlers.reCaptcha.postMessage(['didExpire']);
 }
 */


extension CaptchaViewControllerSwiftUI {
    
    private var generateHTML: String {
        var hCaptchaHTML =
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
        """
        hCaptchaHTML = hCaptchaHTML.replacingOccurrences(of: "${sitekey}", with: self.siteKey)
        return hCaptchaHTML
    }
}

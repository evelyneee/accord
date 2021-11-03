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

struct SwappedLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
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
                                viewModel.login(email, password, twofactor)
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
                    .onAppear(perform: {
                        print(captchaPublicKey, "fucking hell")
                    })
                    .transition(AnyTransition.moveAway)
            case .twofactor:
                VStack {
                    Text("Enter your two-factor code here.")
                    TextField("2fa code", text: $twofactor)
                    Button("Login") {
                        self.captchaPayload = notif["key"] as? String ?? ""
                        NetworkHandling.shared.login(username: email, password: password, captcha: captchaPayload!) { success, array in
                            if success {
                                if let returnArray = try? JSONSerialization.jsonObject(with: array ?? Data(), options: []) as? [String:Any] {
                                    if let ticket = returnArray["ticket"] as? String {
                                        print("[Login debug] Got ticket")
                                        NetworkHandling.shared.requestData(url: "https://discord.com/api/v9/auth/mfa/totp", token: nil, json: true, type: .POST, bodyObject: ["code": twofactor, "ticket": ticket]) { success, data_login in
                                            if success {
                                                print("[Accord] log in kek")
                                                print(String(decoding: data_login!, as: UTF8.self))
                                                if let loginReturnArray = try? JSONSerialization.jsonObject(with: data_login ?? Data(), options: []) as? [String:Any] {
                                                    if let checktoken = loginReturnArray["token"] as? String {
                                                        _ = KeychainManager.save(key: "me.evelyn.accord.token", data: checktoken.data(using: String.Encoding.utf8) ?? Data())
                                                        AccordCoreVars.shared.token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
                                                        captcha = false
                                                    }
                                                }
                                            }
                                        }
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
    
    func login(_ email: String, _ password: String, _ twofactor: String) {
        NetworkHandling.shared.login(username: email, password: password) { success, array in
            if success {
                if let returnArray = try? JSONSerialization.jsonObject(with: array ?? Data(), options: []) as? [String:Any] {
                    if let checktoken = returnArray["token"] as? String {
                        _ = KeychainManager.save(key: "me.evelyn.accord.token", data: checktoken.data(using: String.Encoding.utf8) ?? Data())
                        AccordCoreVars.shared.token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
                    } else {
                        print("[Login debug] Captcha demanded \(returnArray)")
                        if let captchaKey = returnArray["captcha_sitekey"] {
                            DispatchQueue.main.async {
                                self.captchaVCKey = captchaKey as? String ?? ""
                                captchaPublicKey = self.captchaVCKey!
                                self.state = .captcha
                            }
                        } else if let ticket = returnArray["ticket"] as? String {
                            print("[Login debug] Got ticket")
                            NetworkHandling.shared.requestData(url: "https://discord.com/api/v9/auth/mfa/totp", token: nil, json: true, type: .POST, bodyObject: ["code": twofactor, "ticket": ticket]) { success, data_login in
                                if success {
                                    print("[Accord] log in kek")
                                    print(String(decoding: data_login!, as: UTF8.self))
                                    if let loginReturnArray = try? JSONSerialization.jsonObject(with: data_login ?? Data(), options: []) as? [String:Any] {
                                        if let checktoken = loginReturnArray["token"] as? String {
                                            _ = KeychainManager.save(key: "me.evelyn.accord.token", data: checktoken.data(using: String.Encoding.utf8) ?? Data())
                                            AccordCoreVars.shared.token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
                                            self.captcha = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

class LoginResponse: Decodable {
    var token: String?
    var captcha_sitekey: String?
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
            print(generateHTML(self.siteKey), siteKey)
            webView.loadHTMLString(generateHTML(self.siteKey), baseURL: URL(string: "https://discord.com")!)
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

extension CaptchaViewControllerSwiftUI {
    
    private func generateHTML(_ sitekey: String) -> String {
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
                    transform: scale(3.2);
                    -webkit-transform: scale(3.2);
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
        hCaptchaHTML = hCaptchaHTML.replacingOccurrences(of: "${sitekey}", with: sitekey)
        return hCaptchaHTML
    }
}

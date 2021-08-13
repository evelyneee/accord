//
//  DiscordCoreVars.swift
//  Accord
//
//  Created by evelyn on 2020-11-27.
//

import Foundation

public let rootURL: String = "https://discord.com/api/v9"
public let gatewayURL: String = "wss://gateway.discord.gg"
public let cdnURL: String = "https://cdn.discordapp.com"
public var user_id: String = ""
public var avatar: Data = Data()
public var pfpShown: Bool = UserDefaults.standard.bool(forKey: "pfpShown")
public var sortByMostRecent: Bool = UserDefaults.standard.bool(forKey: "sortByMostRecent")
public var darkMode: Bool = UserDefaults.standard.bool(forKey: "darkMode")
public var username: String = ""
public var discriminator: String = ""
public var proxyIP: String? = UserDefaults.standard.string(forKey: "proxyIP")
public var proxyPort: String? = UserDefaults.standard.string(forKey: "proxyPort")
public var proxyEnabled: Bool = UserDefaults.standard.bool(forKey: "proxyEnabled")


final class AccordCoreVars {
    static var shared = AccordCoreVars()
    init(_ tokenOverride: String = "") {
        if tokenOverride != "" {
            token = tokenOverride
        } else {
            token = String(decoding: KeychainManager.load(key: "me.evelyn.accord.token") ?? Data(), as: UTF8.self)
        }
    }
    
    public var token: String = ""
    public var user: User?
}

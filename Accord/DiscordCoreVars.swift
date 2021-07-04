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
public var username: String = ""
public var discriminator: String = ""
public var token: String = String(decoding: KeychainManager.load(key: "token") ?? Data(), as: UTF8.self)

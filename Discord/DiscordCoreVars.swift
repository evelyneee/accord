//
//  backendClient.swift
//  Helselia
//
//  Created by evelyn on 2020-11-27.
//

import Foundation

//public let rootURL: String = "https://constanze.live/api/v1"
//public let gatewayURL: String = "wss://gateway.constanze.live"
public let rootURL: String = "https://discord.com/api/v6"
public let gatewayURL: String = "wss://gateway.discord.gg"
public let cdnURL: String = "https://cdn.discordapp.com"
public let clubsorguilds: String = "guilds"
// wss://gateway.discord.gg
public var user_id: String = ""
public var avatar: Data = Data()
public var pfpShown: Bool = UserDefaults.standard.bool(forKey: "pfpShown")
public var username: String = ""
public var discriminator: String = ""
public var token: String = String(decoding: KeychainManager.load(key: "token") ?? Data(), as: UTF8.self)

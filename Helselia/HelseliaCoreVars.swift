//
//  backendClient.swift
//  Helselia
//
//  Created by evelyn on 2020-11-27.
//

import Foundation
import CryptoKit

var issueContainer: [String] = []

public var token: String = (UserDefaults.standard.string(forKey: "token") ?? "")
public var user_id: String = ""
public var avatar: Data = Data()
public var pfpShown: Bool = UserDefaults.standard.bool(forKey: "pfpShown")
public var username: String = ""
public var discriminator: String = ""
// test account token lol
//public var token = "MTg5MDY3NjE1NzA3MjA2ODkw.YLv6QA.Bf62iIlcZmwm3DRc4tWuyS9fbyc"

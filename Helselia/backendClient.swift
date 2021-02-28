//
//  backendClient.swift
//  Helselia
//
//  Created by althio on 2020-11-27.
//

import Foundation
import CryptoKit

public var messageControlTransfer: String = "hello"

public var accountName = "whattheclap"

public var pronouns = "they/them"

public var openIssues = 5

public var totalIssues = 103

public var usedLanguages = "Objective-C, Swift, Python"

public var backendUsername = "althio"

public var backendUsernameStorage: [String: String] = [:]
public var backendMessageStorage: [String: String] = [:]

public var selectedTab = 0

public var enablePFP = true
// HASHER

func encryptSelectToken(token: String) -> String{
    let inputToken = token.data(using: .utf8)!
    let encryptToken = SHA256.hash(data: inputToken)
    let stringHash = encryptToken.map { String(format: "%02hhx", $0) }.joined()
    return stringHash
}

public var refLinks: [String: String] = [:]

var issueContainer: [String] = []


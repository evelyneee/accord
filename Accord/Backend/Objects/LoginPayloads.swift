//
//  LoginPayloads.swift
//  Accord
//
//  Created by evelyn on 2021-11-09.
//

import Foundation

class LoginResponse: Decodable {
    var token: String?
    var captcha_sitekey: String?
    var ticket: String?
    var code: Int?
    var message: String?
}

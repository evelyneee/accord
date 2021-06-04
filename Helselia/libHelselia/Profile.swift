//
//  Profile.swift
//  Helselia
//
//  Created by evelyn on 2021-06-04.
//

import Foundation

final class ProfileManager {
    static var shared = ProfileManager()
    func getSelfProfile(key: String) -> [Any] {
        var completion: Bool = false
        var returnArray: [Any] = []
        net.requestData(url: "https://constanze.live/api/v1/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
            if let gooddata = data {
                do {
                    let profile = try JSONSerialization.jsonObject(with: gooddata, options: .mutableContainers) as? [String:Any] ?? [String:Any]()
                    for items in profile.keys {
                        if items == key {
                            returnArray.append(profile[items])
                        }
                    }
                } catch {
                    
                }
            }
        }
        while completion == false {
            if returnArray.isEmpty == false {
                completion = true
                print("returned properly \(Date())")
                return returnArray
            }
        }
    }
}

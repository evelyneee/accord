//
//  Profile.swift
//  Helselia
//
//  Created by evelyn on 2021-06-04.
//

import Foundation

final class ProfileManager {
    static var shared = ProfileManager()
    func getSelfProfile(key: String, data: Data?) -> [Any] {
        var returnArray: [Any] = []

        if let gooddata = data {
            do {
                let profile = try JSONSerialization.jsonObject(with: gooddata, options: .mutableContainers) as? [String:Any] ?? [String:Any]()
                for items in profile.keys {
                    if items == key {
                        returnArray.append(profile[items] as Any)
                    }
                }
            } catch {
                
            }
        }
        return returnArray
    }
}

//
//  ClubChannelManager.swift
//  Helselia
//
//  Created by evelyn on 2021-06-13.
//

import Foundation

enum club {
    case id
    case name
    case members
}

enum channel {
    case id
    case name
}

final class ClubManager {
    static var shared = ClubManager()
    var clubCache: [String:Data] = [:]
    var currentClub: String = ""
    func getClub(clubid: String, type: club) -> [Any] {
        var completion: Bool = false

        var returnArray: [Any] = []
        currentClub = clubid
        if self.clubCache[clubid] != nil {
            do {
                let clubArray = try JSONSerialization.jsonObject(with: self.clubCache[clubid] ?? Data(), options: .mutableContainers) as? [[String:Any]] ?? [[String:Any]]()
                if let channel = clubArray as? Array<Dictionary<String, Any>> {
                    if type == .id {
                        for i in 0..<(clubArray as? [[String:Any]] ?? []).count {
                            returnArray.append(channel[i]["id"] as Any)
                        }
                    }
                    if type == .name {
                        for i in 0..<(clubArray as? [[String:Any]] ?? []).count {
                            returnArray.append(channel[i]["name"] as Any)
                        }
                    }
                }
                return returnArray
            } catch {
                
            }
        } else {
            net.requestData(url: "\(rootURL)/\(clubsorguilds)/\(clubid)/channels", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                if let gooddata = data {
                    self.clubCache[clubid] = data ?? Data()
                    do {
                        let clubArray = try JSONSerialization.jsonObject(with: gooddata, options: .mutableContainers) as? [[String:Any]] ?? [[String:Any]]()
                        if let channel = clubArray as? Array<Dictionary<String, Any>> {
                            if type == .id {
                                for i in 0..<(clubArray as? [[String:Any]] ?? []).count {
                                    returnArray.append(channel[i]["id"] as Any)
                                }
                            }
                            if type == .name {
                                for i in 0..<(clubArray as? [[String:Any]] ?? []).count {
                                    returnArray.append(channel[i]["name"] as Any)
                                }
                            }
                        }
                    } catch {
                        
                    }
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

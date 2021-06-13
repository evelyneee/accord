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
    func getClub(clubid: String, type: club) -> [Any] {
        var completion: Bool = false
        var returnArray: [Any] = []
        net.requestData(url: "https://constanze.live/api/v1/clubs/\(clubid)", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
            if let gooddata = data {
                do {
                    let clubArray = try JSONSerialization.jsonObject(with: gooddata, options: .mutableContainers) as? [String:Any] ?? [String:Any]()
                    for item in clubArray.keys {
                        if item == "channels" {
                            if let channel = clubArray[item] as? Array<Dictionary<String, Any>> {
                                if type == .id {
                                    for i in 0..<(clubArray[item] as? [[String:Any]] ?? []).count {
                                        returnArray.append(channel[i]["id"])
                                    }
                                }
                                if type == .name {
                                    for i in 0..<(clubArray[item] as? [[String:Any]] ?? []).count {
                                        returnArray.append(channel[i]["name"])
                                    }
                                }
                            }
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
//    func getChannel(channelid: String, type: channel) -> [Any] {
//        var completion: Bool = false
//        var returnArray: [Any] = []
//        net.requestData(url: "https://constanze.live/api/v1/channels/\(channelid)", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
//            if let gooddata = data {
//                do {
//                    let channelArray = try JSONSerialization.jsonObject(with: gooddata, options: .mutableContainers) as? [String:Any] ?? [String:Any]()
//                    print(channelArray)
//                    for item in channelArray.keys {
//                        if type == .name {
//                            returnArray.append(channel[0]["id"])
//                            print(returnArray)
//                        }
//                    }
//                } catch {
//
//                }
//            }
//        }
//        while completion == false {
//            if returnArray.isEmpty == false {
//                completion = true
//                print("returned properly \(Date())")
//                return returnArray
//            }
//        }
//    }
}

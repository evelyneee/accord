//
//  MessageEndpoint.swift
//  Helselia
//
//  Created by evelyn on 2021-03-07.
//

import Foundation

public class parseMessages {
    func getItem(forKey: String, secondary: Bool, secondaryItem: String, messageDictionary: [[String:Any]], position: Int) -> Any {
        var returnItem: Any = ""
        for item in messageDictionary[position].keys {
            if item == forKey {
                returnItem = messageDictionary[position][item] ?? ""
                break
            } else {
                returnItem = "Key Not Found In Item."
            }
        }
        if secondary == true {
            if type(of: returnItem) == Dictionary<String, Any>.self {
                for i in (returnItem as! Dictionary<String, Any>).keys {
                    if i == secondaryItem {
                        returnItem = secondaryItem
                    }
                }
            }
        }
        return returnItem
    }
    func getArray(forKey: String, messageDictionary: [[String:Any]]) -> [Any] {
        var returnItem: [Any] = []
        for message in messageDictionary {
            for item in message.keys {
                if item == forKey {
                    if forKey == "author" {
                        returnItem.append("\((message[item] as! Dictionary<String, Any>)["username"] ?? "error")#\((message[item] as! Dictionary<String, Any>)["discriminator"] ?? "0000")" )
                    } else if forKey == "embeds" {
                        returnItem.append("\((message[item] as! Dictionary<String, Any>)["username"] ?? "error")#\((message[item] as! Dictionary<String, Any>)["discriminator"] ?? "0000")" )
                    } else {
                        returnItem.append(message[item] ?? "")
                    }
                }
            }
        }
        return returnItem
    }
}

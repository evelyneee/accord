//
//  Status.swift
//  Status
//
//  Created by evelyn on 2021-08-27.
//

import Foundation

final class Status: Codable {
    var text: String?
    // var expires_at: String?
    var emoji_name: String?
    var emoji_id: String?
}

final class Activity: Identifiable {
    internal init(applicationID: String? = nil, flags: Int? = nil, emoji: StatusEmoji? = nil, name: String, type: Int, metadata: [String:Any]? = nil, timestamp: Int? = nil, endTimestamp: Int? = nil, state: String? = nil, details: String? = nil, assets: [String: String] = [:], syncID: String? = nil) {
        self.applicationID = applicationID
        self.flags = flags
        self.emoji = emoji
        self.name = name
        self.type = type
        self.metadata = metadata
        self.timestamp = timestamp
        self.endTimestamp = endTimestamp
        self.state = state
        self.details = details
        self.assets = assets
        self.syncID = syncID
    }

    static var current: Activity?

    var id: String { self.name + (state ?? "") }
    var emoji: StatusEmoji?
    var name: String
    var state: String?
    var type: Int
    var timestamp: Int?
    var endTimestamp: Int?
    var applicationID: String?
    var flags: Int?
    var details: String?
    var syncID: String?
    var assets: [String: String]
    var metadata: [String:Any]?
    var dictValue: [String: Any] {
        var dict: [String: Any] = ["name": name, "type": type, "state": NSNull()]
        if let emoji = emoji {
            dict["emoji"] = emoji.dictValue
        }
        if let state = state {
            dict["state"] = state
        }
        if type != 4 {
            dict["assets"] = assets
            dict["party"] = [:]
            dict["secrets"] = [:]
        }
        if name == "Spotify" {
            dict["party"] = ["id":"spotify:"+user_id]
        }
        if let metadata = metadata {
            dict["metadata"] = metadata
        }
        if let syncID = syncID {
            dict["sync_id"] = syncID
        }
        if name != "Custom Status" {
            dict["application_id"] = applicationID ?? NSNull()
        }
        if let timestamp = timestamp, let endTimestamp = endTimestamp {
            dict["timestamps"] = ["start": timestamp, "end": endTimestamp]
        } else if let timestamp = timestamp {
            dict["timestamps"] = ["start": timestamp]
        }
        if let flags = flags {
            dict["flags"] = flags
        }
        if let details = details {
            dict["details"] = details
        }
        print(dict)
        return dict
    }
}

final class StatusEmoji: Codable {
    internal init(name: String?, id: String?, animated: Bool?) {
        self.name = name
        self.id = id
        self.animated = animated
    }

    var name: String?
    var id: String?
    var animated: Bool?
    var dictValue: [String: Any?] {
        ["name": name as Optional<Any>, "id": id, "animated": animated].compactMapValues { $0 }
    }
}

final class ActivityCodable: Codable {
    var emoji: StatusEmoji?
    var name: String
    var state: String?
    var type: Int
    var timestamp: Int?
    var applicationID: String?
    var flags: Int?
    var details: String?
    var dictValue: [String: Any] {
        var dict: [String: Any?] = ["name": name, "type": type, "state": NSNull()]
        if let emoji = emoji {
            dict["emoji"] = emoji.dictValue
        }
        if let state = state {
            dict["state"] = state
        }
        if type == 0 {
            dict["assets"] = [:]
            dict["party"] = [:]
            dict["secrets"] = [:]
        }
        if name != "Custom Status" {
            dict["application_id"] = applicationID ?? NSNull()
        }
        if let timestamp = timestamp {
            dict["timestamps"] = ["start": timestamp]
        }
        if let flags = flags {
            dict["flags"] = flags
        }
        if let details = details {
            dict["details"] = details
        }
        return dict.compactMapValues { $0 }
    }
}

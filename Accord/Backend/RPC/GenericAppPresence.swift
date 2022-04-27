//
//  GenericAppPresence.swift
//  Accord
//
//  Created by Serena on 22/04/2022.
//

import Foundation
import AppKit

class GenericAppPresence {
    private let app: NSRunningApplication
    private let details: String?
    private let iconURL: String?
    private let startDate = Int(Date().timeIntervalSince1970) * 1000
    
    init(withApp app: NSRunningApplication, details: String? = nil, iconURL: String? = nil) {
        self.app = app
        self.details = details
        self.iconURL = iconURL
    }
    
    
    func updatePresence(status: String? = nil) {
        guard let appName = app.localizedName else {
            print("Couldn't get app name. we out.")
            return
        }
        var assets: [String: String] = [:]
        if let iconURL = iconURL {
            assets["large_image"] = "mp:\(iconURL)"
        }
        
        do {
            try wss.updatePresence(status: status ?? MediaRemoteWrapper.status ?? "dnd", since: startDate) {
                Activity(
                    name: appName,
                    type: 0,
                    timestamp: startDate,
                    details: details,
                    assets: assets
                )
            }
             print("clled wss.updatePresence for app \(appName). We out here")
        } catch {
            print("Error with updating wss.updatePresence: \(error)")
        }
    }
}

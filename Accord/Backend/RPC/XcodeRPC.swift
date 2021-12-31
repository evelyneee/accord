//
//  XcodeRPC.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Foundation
import Cocoa
import Combine

final class XcodeRPC {
        
    enum XcodeScripts: String {
        case windowNames = "return name of windows"
        case filePaths = "return file of documents"
        case documentNames = "return name of documents"
        case activeWorkspaceDocument = "return active workspace document"
    }
    
    static var started = Int(Date().timeIntervalSince1970) * 1000
    
    class func runAPScript(_ s: XcodeScripts) -> [String] {
        let scr = """
        tell application "Xcode"
            \(s.rawValue)
        end tell
        """

        // execute the script
        let script = NSAppleScript.init(source: scr)
        var error: NSDictionary?
        let result = script?.executeAndReturnError(&error)

        // format the result as a Swift array
        if let desc = result {
            var arr: [String] = []
            if desc.numberOfItems == 0 {
                return arr
            }
            for i in 1...desc.numberOfItems {
                let strVal = desc.atIndex(i)!.stringValue
                if var uwStrVal = strVal {
                    // remove " — Edited" suffix if it exists
                    if uwStrVal.hasSuffix(" — Edited") {
                        uwStrVal.removeSubrange(uwStrVal.lastIndex(of: "—")!...)
                        uwStrVal.removeLast()
                    }
                    arr.append(uwStrVal)
                }
            }
            return arr
        } else {
            return []
        }
    }

    class func getActiveFilename() -> String {
        let fileNames = runAPScript(.documentNames)

        let windows = runAPScript(.windowNames)

        for name in windows {
            if fileNames.map({ $0.contains(name.components(separatedBy: " — ").last ?? name) }).contains(true) {
                return name.components(separatedBy: " — ").last ?? name
            }
        }
        return "nothing"
    }

    class func getActiveWorkspace() -> String? {
        let awd = runAPScript(.activeWorkspaceDocument)
        if awd.count >= 2 {
            return awd[1]
        }
        return nil
    }
    
    class func updatePresence(status: String? = nil, workspace: String, filename: String) {
        do {
            print("sent")
            try wss.updatePresence(status: status ?? MediaRemoteWrapper.status ?? "dnd", since: started, activities: [
                Activity.current!,
                Activity(
                    applicationID: xcodeRPCAppID,
                    flags: 1,
                    name: "Xcode",
                    type: 0,
                    timestamp: started,
                    state: "Editing \(filename)",
                    details: "In \(workspace)"
                )
            ])
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                Self.updatePresence(status: status, workspace: Self.getActiveWorkspace() ?? workspace, filename: Self.getActiveFilename())
            })
        } catch {}
    }
}




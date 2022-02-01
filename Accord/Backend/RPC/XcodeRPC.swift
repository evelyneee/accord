//
//  XcodeRPC.swift
//  Accord
//
//  Created by evelyn on 2021-12-30.
//

import Cocoa
import Combine
import Foundation
import OSAKit

final class XcodeRPC {
    static var started = Int(Date().timeIntervalSince1970) * 1000

    class func runXcodeScript(_ script: String) -> [String] {
        let scr = """
        tell application "Xcode"
            \(script)
        end tell
        """

        // execute the script
        let script = NSAppleScript(source: scr)
        let result = script?.executeAndReturnError(nil)
        guard let desc = result?.literalArray, !desc.isEmpty else { return [] }
        return desc.map { value -> String in
            if value.hasSuffix(" — Edited") {
                return value.dropLast(9).stringLiteral
            } else {
                return value
            }
        }
    }

    class func getActiveFilename() -> String? {
        let fileNames = runXcodeScript("return name of documents")

        let windows = runXcodeScript("return name of windows")

        for name in windows {
            if fileNames.map({ $0.contains(name.components(separatedBy: " — ").last ?? name) }).contains(true) {
                return name.components(separatedBy: " — ").last ?? name
            }
        }
        return nil
    }

    class func getActiveWorkspace() -> String? {
        let awd = runXcodeScript("return active workspace document")
        if awd.count >= 2 {
            return awd[1]
        }
        return nil
    }

    class func updatePresence(status: String? = nil, workspace: String, filename: String?) {
        do {
            try wss.updatePresence(status: status ?? MediaRemoteWrapper.status ?? "dnd", since: started) {
                Activity.current!
                Activity(
                    applicationID: xcodeRPCAppID,
                    flags: 1,
                    name: "Xcode",
                    type: 0,
                    timestamp: started,
                    state: filename != nil ? "Editing \(filename!)" : "Idling.",
                    details: "In \(workspace)"
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                let active = Self.getActiveFilename()
                guard active != filename else { return }
                Self.updatePresence(status: status, workspace: Self.getActiveWorkspace() ?? workspace, filename: active)
            }
        } catch {}
    }
}

extension NSAppleEventDescriptor {
    var literalArray: [String] {
        var arr: [String?] = []
        for i in 1 ... numberOfItems {
            arr.append(atIndex(i)?.stringValue)
        }
        return arr.compactMap(\.self)
    }
}

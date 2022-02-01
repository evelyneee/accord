//
//  VisualStudioCodeRPC.swift
//  Accord
//
//  Created by evelyn on 2022-01-06.
//

import Cocoa
import Foundation

final class VisualStudioCodeRPC {
    static var started = Int(Date().timeIntervalSince1970) * 1000

    class func getVSCodeWindowName() -> [String] {
        _ = CGWindowListCreateImage(
            CGRect(x: 0, y: 0, width: 1, height: 1),
            .optionOnScreenOnly,
            kCGNullWindowID,
            []
        )

        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements)
        let cgWindowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let cgWindowListInfo2 = cgWindowListInfo as NSArray? as? [[String: Any]]
        guard let windows = (cgWindowListInfo2?.filter { $0["kCGWindowOwnerName"] as? String == "Code" }.compactMap { $0["kCGWindowName"] as? String }) else { return [] }
        print(windows.filter { $0 != "Code" && $0 != "" && $0 != "Focus Proxy" && $0 != "Menubar" })
        return windows.filter { $0 != "Code" && $0 != "" && $0 != "Focus Proxy" && $0 != "Menubar" }
    }

    class func getRPCInfo() -> (file: String?, workspace: String?) {
        guard let name: String = getVSCodeWindowName().first else { return (file: nil, workspace: nil) }
        var array = [String]()
        if name.contains("—") {
            array = name.components(separatedBy: " — ")
        } else {
            array = [name]
        }
        if array.count == 2 {
            let file = array[0]
            let workspace = array[1]
            return (file: file, workspace: workspace)
        } else if let file = array.first {
            return (file: file, workspace: nil)
        } else {
            return (file: nil, workspace: nil)
        }
    }

    class func updatePresence(status: String? = nil) {
        let info = Self.getRPCInfo()
        try? wss.updatePresence(status: status ?? MediaRemoteWrapper.status ?? "dnd", since: started) {
            Activity.current!
            Activity(
                applicationID: vsCodeRPCAppID,
                flags: 1,
                name: "Visual Studio Code",
                type: 0,
                timestamp: started,
                state: info.file != nil ? "Editing \(info.file!)" : "Idling.",
                details: info.workspace != nil ? "In \(info.workspace!)" : "No workspace"
            )
        }
    }
}

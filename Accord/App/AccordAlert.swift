//
//  AccordAlert.swift
//  Accord
//
//  Created by evelyn on 2022-01-01.
//

import Foundation
import AppKit

extension AccordApp {
    public static func error(_ error: Error, additionalDescription: String? = nil) {
        let alert = NSAlert()
        alert.messageText = error.localizedDescription
        if let additionalDescription = additionalDescription {
            alert.informativeText = additionalDescription
        }
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        guard let window = NSApplication.shared.keyWindow else { return }
        alert.beginSheetModal(for: window, completionHandler: { res in
            print(res)
        })
    }
}

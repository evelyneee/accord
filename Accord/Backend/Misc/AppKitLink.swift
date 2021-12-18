//
//  AppKitLink.swift
//  Accord
//
//  Created by evelyn on 2021-12-18.
//

import Foundation
import AppKit

final class AppKitLink<T: NSView> {
    func introspectView(_ root: NSView, _ completion: @escaping ((_ nsView: T, _ subviewCount: Int) -> Void)) {
        for child in root.subviews {
            if let view = child as? T {
                completion(view, child.subviews.count)
            } else {
                introspectView(child, completion)
            }
        }
    }
    func introspect(_ completion: @escaping ((_ nsView: T, _ subviewCount: Int) -> Void)) {
        guard let view = NSApplication.shared.keyWindow?.contentView else { return }
        for child in view.subviews {
            if let child = child as? T {
                completion(child, child.subviews.count)
            } else {
                introspectView(child, completion)
            }
        }
    }
}

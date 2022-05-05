//
//  AppKitLink.swift
//  Accord
//
//  Created by evelyn on 2021-12-18.
//

import AppKit
import Foundation

final class AppKitLink<V: NSView> {
    class func introspectView(_ root: NSView, _ completion: @escaping ((_ nsView: V, _ subviewCount: Int) -> Void)) {
        for child in root.subviews {
            if let view = child as? V {
                completion(view, child.subviews.count)
            } else {
                introspectView(child, completion)
            }
        }
    }

    class func introspect(_ completion: @escaping ((_ nsView: V, _ subviewCount: Int) -> Void)) {
        guard let view = NSApplication.shared.keyWindow?.contentView else { return }
        for child in view.subviews {
            if let child = child as? V {
                completion(child, child.subviews.count)
            } else {
                introspectView(child, completion)
            }
        }
    }
}

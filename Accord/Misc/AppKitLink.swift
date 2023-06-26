//
//  AppKitLink.swift
//  Accord
//
//  Created by evelyn on 2021-12-18.
//

import AppKit
import Foundation
import SwiftUI

final class AppKitLink<V: NSView> {
    
    var stop: UnsafeMutablePointer<Bool>
    
    init(_ stop: UnsafeMutablePointer<Bool>) {
        self.stop = stop
    }
    
    @_optimize(speed) @MainActor
    func introspectView(_ root: NSView, _ completion: @escaping ((_ nsView: V, _ subviewCount: Int) -> Void)) {
        for child in root.subviews {
            if let view = child as? V {
                self.stop.pointee = true
                completion(view, child.subviews.count)
            } else if !self.stop.pointee {
                introspectView(child, completion)
            }
        }
    }
    
    @_optimize(speed) @MainActor
    func introspect(_ completion: @escaping ((_ nsView: V, _ subviewCount: Int) -> Void)) {
        guard let view = NSApplication.shared.keyWindow?.contentView else { return }
        for child in view.subviews {
            if let child = child as? V {
                self.stop.pointee = true
                completion(child, child.subviews.count)
            } else if !self.stop.pointee {
                introspectView(child, completion)
            }
        }
    }
    
    deinit {
        self.stop.deallocate()
    }
}

struct FetchScrollView: NSViewRepresentable {
    let view = NSTextField(string: "")
    @State var tableView: NSTableView? = nil

    func makeNSView(context _: Context) -> NSView {
        view
    }

    func getTableView() -> NSTableView? {
        guard let cell = view.superview?.superview?.superview else { return nil }
        let tableView = Mirror(reflecting: cell)
            .children
            .filter { $0.label == "enclosingTableView" }
            .first?.value as? NSTableView
        return tableView
    }

    func setTableView() {
        tableView = getTableView()
    }

    func updateNSView(_: NSView, context _: Context) {}
}

class ListTableCellView: NSView {
    // (label: Optional("host"), value: Optional(<_TtGC7SwiftUI15CellHostingViewGVS_15ModifiedContentVS_14_ViewList_ViewVS_19CellContentModifier__: 0x7f8f049a5800>)),
    // var enclosingTableView: Any?
    // (label: Optional("delegate"), value: Optional(<_TtGC7SwiftUI26NSTableViewListCoordinatorGVS_19ListStyleDataSourceOs5Never_GOS_19SelectionManagerBoxS2___: 0x7f8f05192940>))
}

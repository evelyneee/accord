//
//  NSTableView++.swift
//  Accord
//
//  Created by evelyn on 2022-11-21.
//

import AppKit

extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        backgroundColor = NSColor.clear
        if let esv = enclosingScrollView {
            esv.drawsBackground = false
        }
    }
}

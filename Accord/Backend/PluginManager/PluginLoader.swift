//
//  PluginLoader.swift
//  Accord
//
//  Created by evelyn on 2021-10-25.
//

import Foundation
import ObjectiveC
import Darwin
import AppKit

@objc protocol AccordPlugin {
    var name: String { get }
    var body: NSViewController { get set }
    func appendToTextField(text: String)
}

final class Plugins {
    func load(url: URL) -> NSViewController {
        let string = (url.absoluteString) as CFString
        let handle = dlopen(CFStringGetCStringPtr(string, 134217984)!, RTLD_LAZY)
        let bufferPointer = UnsafeRawBufferPointer.init(start: handle, count: 50)
        for (index, byte) in bufferPointer.enumerated() {
          print("byte \(index): \(byte)")
        }
        let ptr = dlsym(handle, "Plugin")
        
        let typedPointer = ptr?.load(as: AccordPlugin.self)
        return typedPointer!.body
    }
}
                        

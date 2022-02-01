//
//  PluginLoader.swift
//  Accord
//
//  Created by evelyn on 2021-10-25.
//

import AppKit
import Darwin
import Foundation
import ObjectiveC
import SwiftUI

final class Plugins {
    func loadView(url: String) -> AccordPlugin? {
        let pluginClass = LoadPlugin(onto: AccordPlugin.self, dylib: url)?.init()
        return pluginClass
    }

    func LoadPlugin<T>(onto _: T.Type, dylib: String) -> T.Type? {
        guard let handle = dlopen(dylib, RTLD_NOW) else {
            print("Could not open \(dylib) \(String(cString: dlerror()))")
            return nil
        }

        guard let replacement = dlsym(handle, "principalClass") else {
            print("Could not locate principalClass function")
            return nil
        }

        let principalClass = unsafeBitCast(replacement,
                                           to: (@convention(c) () -> UnsafeRawPointer).self)
        return unsafeBitCast(principalClass(), to: T.Type.self)
    }
}

@objc open class AccordPlugin: NSObject {
    override public required init() {}

    open var body: NSView?
    open var name = ""
    open var descript = ""
    open var symbol = ""
}

struct NSViewWrapper: NSViewRepresentable {
    var view: NSView
    init(_ view: NSView) {
        self.view = view
    }

    func makeNSView(context _: Context) -> NSView {
        view
    }

    func updateNSView(_: NSView, context _: Context) {}

    typealias NSViewType = NSView
}

/* Example plugin
 @objc open class AccordPlugin: NSObject {

     override init() {
     }

     open var body: NSView? = NSHostingView(rootView: MainView())
     open var name = "plugin"
 }

 @_cdecl("principalClass")
 public func principalClass() -> UnsafeRawPointer {
     return unsafeBitCast(AccordPlugin.self, to: UnsafeRawPointer.self)
 }

 struct MainView: View {
     var body: some View {
         VStack {
             Text("Hi")
             .fontWeight(.bold)
             .font(.title)
             Text("Hello from the first Accord plugin")
         }
     }
 }
 */

//
//  FlipList.swift
//  Accord
//
//  Created by evelyn on 2022-10-21.
//

import SwiftUI
import Foundation

@objc
class ListReplacementMethods: NSObject {
    @objc func isFlipped() -> ObjCBool {
        return true
    }
}


func makeListFlipHook() {
    let targetCLS = NSClassFromString("SwiftUI.ListCoreTableView")
    let targetMethod = class_getInstanceMethod(targetCLS, NSSelectorFromString("isFlipped"))
    let replacementMethod = class_getInstanceMethod(ListReplacementMethods.self, NSSelectorFromString("isFlipped"))
    method_exchangeImplementations(targetMethod!, replacementMethod!)
}

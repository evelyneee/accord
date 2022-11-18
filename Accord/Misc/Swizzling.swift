//
//  ObjC.swift
//  Accord
//
//  Created by evelyn on 2022-11-17.
//

import ObjectiveC

/// Code taken from ElleKit (https://github.com/evelyneee/ellekit)
/// Please ask for permission before using in another project
/// ElleKit is currently unlicensed, and this code counts as a part of it
public func messageHook(_ cls: AnyClass, _ sel: Selector, _ imp: IMP, _ result: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) {
    guard let method = class_getInstanceMethod(cls, sel) ?? class_getClassMethod(cls, sel) else {
        return print("[-] ellekit: peacefully bailing out of message hook because the method cannot be found")
    }
    
    let old = class_replaceMethod(cls, sel, imp, method_getTypeEncoding(method))
    
    if let result {
        if let old,
           let fp = unsafeBitCast(old, to: UnsafeMutableRawPointer?.self) {
            print("[+] ellekit: Successfully got orig pointer for an objc message hook")
            result.pointee = fp
        } else if let superclass = class_getSuperclass(cls),
                  let ptr = class_getMethodImplementation(superclass, sel),
                  let fp = unsafeBitCast(ptr, to: UnsafeMutableRawPointer?.self) {
            print("[+] ellekit: Successfully got orig pointer from superclass for an objc message hook")
            result.pointee = fp
        }
    }
}

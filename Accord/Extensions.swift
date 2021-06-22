//
//  Extensions.swift
//  Accord
//
//  Created by evelyn on 2021-06-07.
//

import Foundation
import SwiftUI

extension Button {
    func coolButtonStyle() -> some View {
        self.buttonStyle(CoolButtonStyle())
    }
}

extension Dictionary {
    mutating func switchKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
}

extension Dictionary {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
    
}

extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}

extension View {
    func onReceiveNotifs(_ name: Notification.Name,
                   center: NotificationCenter = .default,
                   object: AnyObject? = nil,
                   perform action: @escaping (Notification) -> Void) -> some View {
        self.onReceive(
            center.publisher(for: name, object: object), perform: action
        )
    }
}

extension Color {
    static let featuredColor = Color("FeaturedShadow")
}


func resize(image: NSImage, w: Int, h: Int) -> NSImage {
    var destSize = NSMakeSize(CGFloat(w), CGFloat(h))
    var newImage = NSImage(size: destSize)
    newImage.lockFocus()
    image.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
    newImage.unlockFocus()
    newImage.size = destSize
    return newImage
}

func showNotification(title: String, subtitle: String) -> Void {
            let notification = NSUserNotification()
            notification.title = title
            notification.subtitle = subtitle
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
}

func userNotificationCenter(_ center: NSUserNotificationCenter,
                                         shouldPresent notification: NSUserNotification) -> Bool {
        return true
}

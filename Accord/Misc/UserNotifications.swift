//
//  UserNotifications.swift
//  UserNotifications
//
//  Created by evelyn on 2021-10-17.
//

import AppKit
import Foundation
import UserNotifications

func showNotification(title: String, subtitle: String, description: String? = nil) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.subtitle = subtitle
    if let description = description {
        content.body = description
    }
    let date = Date()
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents, repeats: false
    )
    let uuidString = "Accord"
    let request = UNNotificationRequest(identifier: uuidString,
                                        content: content, trigger: trigger)
    // Schedule the request with the system.
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.add(request) { error in
        if let error = error {
            print(error)
        }
    }
}

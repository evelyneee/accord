//
//  UserNotifications.swift
//  UserNotifications
//
//  Created by evelyn on 2021-10-17.
//

import Foundation
import UserNotifications

func showNotification(title: String, subtitle: String) -> Void {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = subtitle
    let date = Date() // 2018-10-10T10:00:00+00:00
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
       
    // Create the trigger as a repeating event.
    let trigger = UNCalendarNotificationTrigger(
             dateMatching: dateComponents, repeats: false)
    let uuidString = UUID().uuidString
    let request = UNNotificationRequest(identifier: uuidString,
                                        content: content, trigger: trigger)

    // Schedule the request with the system.
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.add(request) { (error) in
       if error != nil {
          // Handle any errors.
       }
    }
}

func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         shouldPresent notification: UNNotification) -> Bool {
        return true
}

func clearAllNotifications() {
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
}

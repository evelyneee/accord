//
//  UserNotifications.swift
//  UserNotifications
//
//  Created by evelyn on 2021-10-17.
//

import AppKit
import Foundation
import UserNotifications
import Intents

func showNotification(title: String, subtitle: String, description: String? = nil, pfpURL: String, id: String) {
    DispatchQueue.global().async {
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
        content.sound = UNNotificationSound.default
        let request = UNNotificationRequest(identifier: id,
                                            content: content, trigger: trigger)
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { error in
            if let error = error {
                print(error)
            }
        }
    }
}

#if false
@available(macOS 12.0, *)
func newNotification(_ message: Message) {
    let content = UNMutableNotificationContent()

    let matchingGuild = Array(ServerListView.folders.map(\.guilds).joined())[message.guild_id ?? ""]
    let matchingChannel = matchingGuild?.channels?[message.channel_id] ?? ServerListView.privateChannels[message.channel_id]
    
    print(matchingChannel)
    
    content.title = message.author?.username ?? "Unknown User"
    if let matchingGuild = matchingGuild, let matchingChannel = matchingChannel {
        content.subtitle = "#\(matchingChannel.computedName) • \(matchingGuild.name ?? "")"
    } else if let matchingChannel = matchingChannel {
        content.subtitle = matchingChannel.name ?? "Direct Messages"
    } else {
        content.subtitle = "Direct Messages"
    }
    content.body = message.content
    content.sound = UNNotificationSound.default
    content.categoryIdentifier = "message"

    var personNameComponents = PersonNameComponents()
    personNameComponents.nickname = message.author?.username ?? "Unknown User"

    print(content)
    
    Request.image(url: URL.init(string: pfpURL(message.author?.id, message.author?.avatar, "128"))) { image in
        if let image = image {
            print(image.averageColor)
            
            let avatar = INImage(imageData: image.tiffRepresentation ?? Data())
                        
            let senderPerson = INPerson(
                personHandle: INPersonHandle(value: message.author?.id ?? "", type: .unknown),
                nameComponents: personNameComponents,
                displayName: personNameComponents.nickname ?? "",
                image: avatar,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: false,
                suggestionType: .none
            )
            
            let mePerson = INPerson(
                personHandle: INPersonHandle(value: user_id, type: .unknown),
                nameComponents: nil,
                displayName: AccordCoreVars.user?.username ?? "",
                image: avatar,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: true,
                suggestionType: .none
            )
            
            print(senderPerson, mePerson)

            let intent = INSendMessageIntent(
                recipients: [mePerson],
                outgoingMessageType: .outgoingMessageText,
                content: message.content,
                speakableGroupName: INSpeakableString(spokenPhrase: matchingChannel?.computedName ?? message.author?.username ?? ""),
                conversationIdentifier: message.channel_id,
                serviceName: nil,
                sender: senderPerson,
                attachments: nil
            )

            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming

            interaction.donate(completion: nil)

            do {
                let content = try content.updating(from: intent)
                
                print(content)
                
                // Show 3 seconds from now
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

                // Choose a random identifier
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                // Add notification request
                UNUserNotificationCenter.current().add(request)
            } catch {
                
                // Handle error
                print(error)
            }
        }
    }
}
#endif

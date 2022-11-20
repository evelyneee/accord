//
//  Engine.swift
//  Accord
//
//  Created by evelyn on 2022-01-21.
//

import Foundation

final class SlashCommands {
    public class func interact(
        type: Int = 2,
        applicationID: String,
        guildID: String,
        channelID: String,
        appVersion: String,
        id: String,
        dataType: Int,
        appName: String,
        appType: Int = 1,
        appDescription: String,
        options: [SlashCommandStorage.Command.Option] = [],
        optionValues: [[String: Any]] = []
    ) throws {
        let boundary = "WebKitFormBoundary\(UUID().uuidString)"
        let optionValues = options
            .prefix(optionValues.count)
            .enumerated()
            .map { index, option -> [String: Any] in
                var value = optionValues[index]
                value["type"] = option.type
                return value
            }
        let params: [String: Any] = [
            "type": type,
            "application_id": applicationID,
            "guild_id": guildID,
            "channel_id": channelID,
            "session_id": wss.sessionID ?? "",
            "data": [
                "options": optionValues,
                "version": appVersion,
                "id": id,
                "type": dataType,
                "name": appName,
                "application_command": [
                    "application_id": applicationID,
                    "default_member_permissions": NSNull(),
                    "default_permission": true,
                    "description": appDescription,
                    "dm_permission": NSNull(),
                    "id": id,
                    "name": appName,
                    "type": appType,
                    "version": appVersion,
                    "options": { () -> Any? in
                        let dict = options.map { option -> [String: Any] in
                            [
                                "description": option.description,
                                "name": option.name,
                                "required": option.required ?? false,
                                "type": option.type,
                            ]
                        }
                        if dict.isEmpty {
                            return nil
                        }
                        return dict
                    }(),
                ].compactMapValues { $0 },
            ],
            "nonce": generateFakeNonce(),
        ]
        
        Request.multipartData(
            url: URL(string: "\(rootURL)/interactions"),
            with: params,
            fileURL: nil,
            boundary: boundary,
            headers: Headers(
                token: Globals.token,
                type: .POST,
                discordHeaders: true,
                referer: "https://discord.com/channels/\(guildID)/\(channelID)"
            )
        ) {
            switch $0 {
            case let .success((_, response)):
                if let response = response,
                   (200 ..< 300).contains(response.statusCode)
                {
                    print("Interaction worked!")
                } else {
                    AccordApp.error(
                        nil,
                        text: "This interaction failed",
                        additionalDescription: "Could not send interaction",
                        reconnectOption: false
                    )
                }
            case let .failure(error):
                print(error)
            }
        }
    }

    final class SlashCommandOption {
        internal init(description: String, name: String, required: Bool? = nil, type: SlashCommands.SlashCommandOptionTypes, value: Any) {
            self.description = description
            self.name = name
            self.required = required
            self.type = type
            self.value = value
        }

        var description: String
        var name: String
        var required: Bool?
        var type: SlashCommandOptionTypes
        var value: Any
    }

    enum SlashCommandOptionTypes: Int, Codable {
        case subCommand = 1, subCommandGroup, string, integer, boolean, user, channel, role, mentionable, number, attachment
    }
}

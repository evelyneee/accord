//
//  Storage.swift
//  Accord
//
//  Created by evelyn on 2022-01-21.
//

import Foundation

final class SlashCommandStorage {
    static var commands: [String: [Command]] = .init()

    final class Command: Codable {
        var application_id: String
        var description: String
        var id: String
        var name: String
        var type: Int
        var version: String
        var avatar: String?
        var options: [Option]?
        final class Option: Codable {
            var description: String
            var type: Int
            var name: String
            var required: Bool?
        }
    }

    final class GuildApplicationCommandsUpdateEvent: Decodable {
        var d: D
        final class D: Decodable {
            var application_commands: [SlashCommandStorage.Command]
            @DefaultEmptyArray
            var applications: [Bot]
            final class Bot: Decodable, Identifiable {
                var icon: String?
                var id: String
            }
        }
    }
}

//
//  Engine.swift
//  Accord
//
//  Created by evelyn on 2022-01-21.
//

import Foundation

func testXP() {
    /*
     {
        "type":2,
        "application_id":"785982039798186014",
        "guild_id":"349243932447604736",
        "channel_id":"688121419980341282",
        "session_id":"d0d59397c3c82237c7c426696574aba0",
        "data":{
            "version":"910922653005676659",
            "id":"910922647485972535",
            "guild_id":"349243932447604736",
            "name":"xp","type":1,
            "options":[],
            "attachments":[],
            "application_command":{
                "id":"910922647485972535",
                "name":"xp",
                "application_id":"785982039798186014",
                "guild_id":"349243932447604736",
                "type":1,
                "description":"Show your or another user's XP",
                "default_permission":true,
                "listed":true,
                "name_localized":"xp",
                "version":"910922653005676659",
                "permissions":[],
                "options":[
                    {
                        "description":"Member to show xp of",
                        "name":"user",
                        "type":6
                    }
                ]
            }
        },
        "nonce":"934248465829986304"
     }
     */
}

final class SlashCommands {
    // {"version":"847239978559078431","id":"847239978559078430","name":"minesweeper","type":1,"options":[],"application_command":{"application_id":"836759847357251604","default_member_permissions":null,"default_permission":true,"description":"play minesweeper on a 5-5-5 board","dm_permission":null,"id":"847239978559078430","name":"minesweeper","permissions":[],"type":1,"version":"847239978559078431"},"attachments":[]}
    public class func interact (
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
        optionValues: [[String:Any]] = []
    ) throws {
        var request = URLRequest(url: URL(string: "\(rootURL)/interactions")!)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let optionValues = options.prefix(optionValues.count).enumerated().map { (index, option) -> [String:Any] in
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
                "attachments": [],
                "guild_id": guildID,
                "application_command": [
                    "application_id":applicationID,
                    "default_member_permissions":NSNull(),
                    "default_permission":true,
                    "description":appDescription,
                    "dm_permission":NSNull(),
                    "id":id,
                    "listed":true,
                    "name":appName,
                    "permissions":[],
                    "type":appType,
                    "version":appVersion,
                    "options": options.map { (option) -> [String:Any] in
                        [
                            "description":option.description,
                            "name":option.name,
                            "required":option.required ?? false,
                            "type":option.type
                        ]
                    }
                ],
            ],
        ]
        request.addValue(AccordCoreVars.token, forHTTPHeaderField: "Authorization")
        guard let params = try params.jsonString() else { return }
        request.httpBody = try Request.createMultipartBody(with: params, boundary: boundary)
        print(String(data: request.httpBody!, encoding: .utf8))
        let task = URLSession.shared.dataTask(with: request)
        task.resume()
    }
    
    /*
     ------WebKitFormBoundary5Vd4WDsAWQVupC0G
     Content-Disposition: form-data; name="payload_json"

     {"type":2,"application_id":"875076982482808932","guild_id":"815369174096412692","channel_id":"839005662931189801","session_id":"203cf36c3283dbf010a05f0867f7f619","data":{"version":"875768589381160975","id":"875768589381160971","name":"bonk","type":1,"options":[{"type":6,"name":"victim","value":"645775800897110047"},{"type":5,"name":"ping","value":false}],"application_command":{"application_id":"875076982482808932","default_member_permissions":null,"default_permission":true,"description":"Bonk someone!","dm_permission":null,"id":"875768589381160971","listed":true,"name":"bonk","options":[
            {"description":"The user you wish to bonk.","name":"victim","required":true,"type":6},
            {"description":"Toggle whether the bonk should ping the victim","name":"ping","type":5}
     ],"permissions":[],"type":1,"version":"875768589381160975"},"attachments":[]},"nonce":"946453678976401408"}
     ------WebKitFormBoundary5Vd4WDsAWQVupC0G--
     */
    
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

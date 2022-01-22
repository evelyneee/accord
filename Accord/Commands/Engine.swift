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
    SlashCommands.interact(
        applicationID: "785982039798186014",
        guildID: "349243932447604736",
        channelID: "688121419980341282",
        appVersion: "910922653005676659",
        id: "910922647485972535",
        dataType: 1,
        appName: "xp",
        command: [
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
                [
                    "description":"Member to show xp of",
                    "name":"user",
                    "type":6
                ]
            ]
        ]
    )
}

final class SlashCommands {
    public class func interact(type: Int = 2, applicationID: String, guildID: String, channelID: String, appVersion: String, id: String, dataType: Int, appName: String, command: [String:Any]) {
        var request = URLRequest(url: URL(string: "\(rootURL)/interactions")!)
        print(request.url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let params: [String: Any] = [
            "type": type,
            "application_id": applicationID,
            "guild_id": guildID,
            "channel_id": channelID,
            "session_id":wss.sessionID ?? "",
            "data": [
                "version": appVersion,
                "id": id,
                "type": dataType,
                "name": appName,
                "options": [],
                "attachments": [],
                "application_command":command
            ]
        ]
        request.addValue(AccordCoreVars.token, forHTTPHeaderField: "Authorization")
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        body.append(string: boundaryPrefix, encoding: .utf8)
        body.append(string: "Content-Disposition: form-data; name=\"payload_json\"\r\n\r\n", encoding: .utf8)
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else { return }
        body.append(data)
        body.append(string: "\r\n", encoding: .utf8)
        body.append(string: "--".appending(boundary.appending("--")), encoding: .utf8)
        body.append(string: "\r\n", encoding: .utf8)
        request.httpBody = body
        print(String(data: request.httpBody!, encoding: .utf8))
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            print(String(data: data!, encoding: .utf8), response, error)
        })
        
        task.resume()
        
        /*
         '------WebKitFormBoundaryj1uZ6lxn0CIyePgA
         Content-Disposition: form-data; name="payload_json"
         
         {"type":2,"application_id":"785982039798186014","guild_id":"349243932447604736","channel_id":"688121419980341282","session_id":"d0d59397c3c82237c7c426696574aba0","data":{"version":"910922653005676659","id":"910922647485972535","guild_id":"349243932447604736","name":"xp","type":1,"options":[],"attachments":[],"application_command":{"id":"910922647485972535","name":"xp","application_id":"785982039798186014","guild_id":"349243932447604736","type":1,"description":"Show your or another user\'s XP","default_permission":true,"listed":true,"name_localized":"xp","version":"910922653005676659","permissions":[],"options":[{"description":"Member to show xp of","name":"user","type":6}]}},"nonce":"934253148392914944"}
         ------WebKitFormBoundaryj1uZ6lxn0CIyePgA--
         '
         */
        
    }
}

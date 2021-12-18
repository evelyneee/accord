//
//  Interaction.swift
//  Accord
//
//  Created by evelyn on 2021-11-20.
//

import Foundation

final class Interaction: Codable {
    var id: String
    var type: Int
    var name: String
    var user: User?
}

final class SlashCommands {
    init() {
        
    }
    final public class func interact(type: Int, applicationID: String, guildID: String, channelID: String, appVersion: String, id: String, dataType: Int, appName: String) {
        /*
         {
         "type":2,
         "application_id":"836759847357251604",
         "guild_id":"815369174096412692",
         "channel_id":"839005662931189801",
         "data":{
            "version":"847239978559078431",
            "id":"847239978559078430",
            "name":"minesweeper",
            "type":1,
            "options":[],
            "attachments":[]
         },
         "nonce":"911725258594058240"
         }
         */
        Request.ping(url: URL(string: "\(rootURL)/interactions"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.shared.token,
            bodyObject: [
                "type":type,
                "application_id":applicationID,
                "guild_id":guildID,
                "channel_id":channelID,
                "data":[
                    "version":appVersion,
                    "id":id,
                    "type":dataType,
                    "name":appName,
                    "options":[],
                    "attachments":[]
                ]
            ],
            type: .POST,
            discordHeaders: true,
            json: true
        ))
    }
}

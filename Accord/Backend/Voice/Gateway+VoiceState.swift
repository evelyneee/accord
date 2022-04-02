//
//  Gateway+VoiceState.swift
//  Accord
//
//  Created by evelyn on 2022-03-13.
//

import Foundation

extension Gateway {
    func updateVoiceState(
        guildID: String?,
        channelID: String?,
        deafened: Bool = false,
        muted: Bool = false,
        streaming: Bool = false
    ) throws {
        let packet: [String: Any] = [
            "op": 4,
            "d": [
                "guild_id": guildID as Any,
                "channel_id": channelID as Any,
                "self_deaf": deafened,
                "self_mute": muted,
                "self_video": streaming,
            ],
        ]
        try send(json: packet)
    }
}

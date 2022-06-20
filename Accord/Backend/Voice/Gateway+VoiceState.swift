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
                "preferred_region": "montreal",
                "self_mute": muted,
                "self_video": streaming,
            ],
        ]
        try send(json: packet)
    }
}

/*
 [GatewaySocket] ~> 4 {guild_id: "825437365027864578", channel_id: "971218660146425876", self_mute: true, self_deaf: false, self_video: false, …}
 f6d32223260bb058a9bf.js:130 [GatewaySocket] ~> 14 {guild_id: "825437365027864578", channels: {…}}
 f6d32223260bb058a9bf.js:130 [RTCControlSocket] ~> 8: {"v":6,"heartbeat_interval":13750}
 f6d32223260bb058a9bf.js:130 [RTCControlSocket] ~> 2: {"streams":[{"type":"video","ssrc":23585,"rtx_ssrc":23586,"rid":"50","quality":50,"active":false},{"type":"video","ssrc":23587,"rtx_ssrc":23588,"rid":"100","quality":100,"active":false}],"ssrc":23584,"port":50010,"modes":["aead_aes256_gcm_rtpsize","aead_aes256_gcm","xsalsa20_poly1305_lite_rtpsize","xsalsa20_poly1305_lite","xsalsa20_poly1305_suffix","xsalsa20_poly1305"],"ip":"35.215.30.230","experiments":["fixed_keyframe_interval"]}
 f6d32223260bb058a9bf.js:130 [RTCControlSocket] ~> 16: {"voice":"0.8.38","rtc_worker":"0.3.20"}
 f6d32223260bb058a9bf.js:130 [RTCControlSocket] ~> 4: {"video_codec":"H264","secret_key":[76,185,56,200,214,160,106,248,111,97,216,210,190,241,35,43,146,150,25,66,161,51,222,19,216,60,229,6,4,252,45,51],"mode":"aead_aes256_gcm_rtpsize","media_session_id":"de801f47e5985cb3216f834b37fc0ed6","audio_codec":"opus"}
 f6d32223260bb058a9bf.js:130 [RTCControlSocket] ~> 15: {"any":100}
 f6d32223260bb058a9bf.js:130 [GatewaySocket] ~> 4 {guild_id: "825437365027864578", channel_id: "971218660146425876", self_mute: true, self_deaf: true, self_video: false, …}
 f6d32223260bb058a9bf.js:130 [GatewaySocket] ~> 1 42
 */

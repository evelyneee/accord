//
//  NetworkHandler.swift
//  Accord
//
//  Created by evelyn on 2021-02-27.
//

import Foundation
import Combine
import AppKit
import SwiftUI

var messagesString: String { return """
[
    {
        "id": "921525883276238948",
        "type": 0,
        "content": "acknowledged <:thumbsHead:804175645911285811>",
        "channel_id": "825437366113271820",
        "author": {
            "id": "334067823229796367",
            "username": "cstanze",
            "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
            "discriminator": "1337",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T22:14:51.696000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921524650159263794",
        "type": 0,
        "content": "This message is a test. Do not acknowledge this message.",
        "channel_id": "825437366113271820",
        "author": {
            "id": "302477497264504833",
            "username": "not.Ryan",
            "avatar": "da8dfb3dad0b88b996485d8f9fe977f8",
            "discriminator": "2118",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T22:09:57.698000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502491663806544",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:54.701000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502487553384458",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:53.721000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502482780266647",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:52.583000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502478791479377",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:51.632000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502474546860042",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:50.620000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502470608392192",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:49.681000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502465931743242",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:48.566000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502460860842075",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:47.357000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502454800056363",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:45.912000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921502448038850611",
        "type": 0,
        "content": "test",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T20:41:44.300000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921475817672966196",
        "type": 0,
        "content": "Fuck nitro",
        "channel_id": "825437366113271820",
        "author": {
            "id": "181784054515892236",
            "username": "Lans",
            "avatar": "a3b1ba60a98c13b806d287cf4d782a06",
            "discriminator": "8561",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T18:55:55.126000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921432795287519313",
        "type": 0,
        "content": "That is true",
        "channel_id": "825437366113271820",
        "author": {
            "id": "531532678135283744",
            "username": "Joey",
            "avatar": "7423912d8cbcc9b6270cfa6c504aa2be",
            "discriminator": "0980",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-17T16:04:57.790000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921174789865996409",
        "type": 19,
        "content": "<a:SCyes:841886073519996979>",
        "channel_id": "825437366113271820",
        "author": {
            "id": "262786101037498369",
            "username": "Worf",
            "avatar": "3adbf1cdb94b376b10e1c05ff573d2b8",
            "discriminator": "5035",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [
            {
                "id": "302477497264504833",
                "username": "not.Ryan",
                "avatar": "da8dfb3dad0b88b996485d8f9fe977f8",
                "discriminator": "2118",
                "public_flags": 256
            }
        ],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T22:59:44.504000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": [],
        "message_reference": {
            "channel_id": "825437366113271820",
            "guild_id": "825437365027864578",
            "message_id": "921139711043567697"
        },
        "referenced_message": {
            "id": "921139711043567697",
            "type": 0,
            "content": "just use classic nitro",
            "channel_id": "825437366113271820",
            "author": {
                "id": "302477497264504833",
                "username": "not.Ryan",
                "avatar": "da8dfb3dad0b88b996485d8f9fe977f8",
                "discriminator": "2118",
                "public_flags": 256
            },
            "attachments": [],
            "embeds": [],
            "mentions": [],
            "mention_roles": [],
            "pinned": false,
            "mention_everyone": false,
            "tts": false,
            "timestamp": "2021-12-16T20:40:21.061000+00:00",
            "edited_timestamp": null,
            "flags": 0,
            "components": []
        }
    },
    {
        "id": "921172120476712980",
        "type": 0,
        "content": "*man*",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T22:49:08.072000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921139739170574346",
        "type": 0,
        "content": "ud83dudc4d",
        "channel_id": "825437366113271820",
        "author": {
            "id": "302477497264504833",
            "username": "not.Ryan",
            "avatar": "da8dfb3dad0b88b996485d8f9fe977f8",
            "discriminator": "2118",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T20:40:27.767000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921139711043567697",
        "type": 0,
        "content": "just use classic nitro",
        "channel_id": "825437366113271820",
        "author": {
            "id": "302477497264504833",
            "username": "not.Ryan",
            "avatar": "da8dfb3dad0b88b996485d8f9fe977f8",
            "discriminator": "2118",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T20:40:21.061000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921139690390818886",
        "type": 0,
        "content": "dont boost anyone",
        "channel_id": "825437366113271820",
        "author": {
            "id": "302477497264504833",
            "username": "not.Ryan",
            "avatar": "da8dfb3dad0b88b996485d8f9fe977f8",
            "discriminator": "2118",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T20:40:16.137000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921015610442407986",
        "type": 0,
        "content": "<:fr:867475246226866226>",
        "channel_id": "825437366113271820",
        "author": {
            "id": "334067823229796367",
            "username": "cstanze",
            "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
            "discriminator": "1337",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:27:13.172000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921015300915347467",
        "type": 0,
        "content": "keep boosting that",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:25:59.375000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921015272821907498",
        "type": 0,
        "content": "A friend's server, been around for 3 years now so it's expected tbf",
        "channel_id": "825437366113271820",
        "author": {
            "id": "334067823229796367",
            "username": "cstanze",
            "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
            "discriminator": "1337",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:25:52.677000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921015012854726666",
        "type": 19,
        "content": "which server",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [
            {
                "id": "334067823229796367",
                "username": "cstanze",
                "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
                "discriminator": "1337",
                "public_flags": 128
            }
        ],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:24:50.696000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": [],
        "message_reference": {
            "channel_id": "825437366113271820",
            "guild_id": "825437365027864578",
            "message_id": "921011191114006599"
        },
        "referenced_message": {
            "id": "921011191114006599",
            "type": 0,
            "content": "So is the other one, I really only want the 12 month badge for like a week",
            "channel_id": "825437366113271820",
            "author": {
                "id": "334067823229796367",
                "username": "cstanze",
                "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
                "discriminator": "1337",
                "public_flags": 128
            },
            "attachments": [],
            "embeds": [],
            "mentions": [],
            "mention_roles": [],
            "pinned": false,
            "mention_everyone": false,
            "tts": false,
            "timestamp": "2021-12-16T12:09:39.522000+00:00",
            "edited_timestamp": null,
            "flags": 0,
            "components": []
        }
    },
    {
        "id": "921014945502593034",
        "type": 19,
        "content": "Which server?",
        "channel_id": "825437366113271820",
        "author": {
            "id": "531532678135283744",
            "username": "Joey",
            "avatar": "7423912d8cbcc9b6270cfa6c504aa2be",
            "discriminator": "0980",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [
            {
                "id": "645775800897110047",
                "username": "evln",
                "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
                "discriminator": "0001",
                "public_flags": 0
            }
        ],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:24:34.638000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": [],
        "message_reference": {
            "channel_id": "825437366113271820",
            "guild_id": "825437365027864578",
            "message_id": "921010886611705887"
        },
        "referenced_message": {
            "id": "921010886611705887",
            "type": 0,
            "content": "keep boosting the other server",
            "channel_id": "825437366113271820",
            "author": {
                "id": "645775800897110047",
                "username": "evln",
                "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
                "discriminator": "0001",
                "public_flags": 0
            },
            "attachments": [],
            "embeds": [],
            "mentions": [],
            "mention_roles": [],
            "pinned": false,
            "mention_everyone": false,
            "tts": false,
            "timestamp": "2021-12-16T12:08:26.923000+00:00",
            "edited_timestamp": "2021-12-16T12:08:34.124000+00:00",
            "flags": 0,
            "components": []
        }
    },
    {
        "id": "921011494609645608",
        "type": 0,
        "content": "~~also the other server isn't even level 1 so....~~",
        "channel_id": "825437366113271820",
        "author": {
            "id": "334067823229796367",
            "username": "cstanze",
            "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
            "discriminator": "1337",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:10:51.881000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921011191114006599",
        "type": 0,
        "content": "So is the other one, I really only want the 12 month badge for like a week",
        "channel_id": "825437366113271820",
        "author": {
            "id": "334067823229796367",
            "username": "cstanze",
            "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
            "discriminator": "1337",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:09:39.522000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921010954857234462",
        "type": 0,
        "content": "this server is dead af",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:08:43.194000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921010925337714728",
        "type": 0,
        "content": "please",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:08:36.156000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921010886611705887",
        "type": 0,
        "content": "keep boosting the other server",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:08:26.923000+00:00",
        "edited_timestamp": "2021-12-16T12:08:34.124000+00:00",
        "flags": 0,
        "components": []
    },
    {
        "id": "921010870161666049",
        "type": 19,
        "content": "please donu2019t",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [
            {
                "id": "334067823229796367",
                "username": "cstanze",
                "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
                "discriminator": "1337",
                "public_flags": 128
            }
        ],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T12:08:23.001000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": [],
        "message_reference": {
            "channel_id": "825437366113271820",
            "guild_id": "825437365027864578",
            "message_id": "921002926871289886"
        },
        "referenced_message": {
            "id": "921002926871289886",
            "type": 19,
            "content": "I was going to double boost but I'm going to reach 12 months in Feb. I'll boost after that <a:AG_FingerGuns:704689393780260918>",
            "channel_id": "825437366113271820",
            "author": {
                "id": "334067823229796367",
                "username": "cstanze",
                "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
                "discriminator": "1337",
                "public_flags": 128
            },
            "attachments": [],
            "embeds": [],
            "mentions": [
                {
                    "id": "645775800897110047",
                    "username": "evln",
                    "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
                    "discriminator": "0001",
                    "public_flags": 0
                }
            ],
            "mention_roles": [],
            "pinned": false,
            "mention_everyone": false,
            "tts": false,
            "timestamp": "2021-12-16T11:36:49.173000+00:00",
            "edited_timestamp": null,
            "flags": 0,
            "components": [],
            "message_reference": {
                "channel_id": "825437366113271820",
                "guild_id": "825437365027864578",
                "message_id": "920876955933499473"
            }
        }
    },
    {
        "id": "921003555085754408",
        "type": 0,
        "content": "Also I had that extra boost lying around and didn't want to let it go to waste",
        "channel_id": "825437366113271820",
        "author": {
            "id": "334067823229796367",
            "username": "cstanze",
            "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
            "discriminator": "1337",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T11:39:18.951000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "921002926871289886",
        "type": 19,
        "content": "I was going to double boost but I'm going to reach 12 months in Feb. I'll boost after that <a:AG_FingerGuns:704689393780260918>",
        "channel_id": "825437366113271820",
        "author": {
            "id": "334067823229796367",
            "username": "cstanze",
            "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
            "discriminator": "1337",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [
            {
                "id": "645775800897110047",
                "username": "evln",
                "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
                "discriminator": "0001",
                "public_flags": 0
            }
        ],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T11:36:49.173000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": [],
        "message_reference": {
            "channel_id": "825437366113271820",
            "guild_id": "825437365027864578",
            "message_id": "920876955933499473"
        },
        "referenced_message": {
            "id": "920876955933499473",
            "type": 0,
            "content": "- whyn- i wanna boost but i canu2019t unboost any server atm",
            "channel_id": "825437366113271820",
            "author": {
                "id": "645775800897110047",
                "username": "evln",
                "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
                "discriminator": "0001",
                "public_flags": 0
            },
            "attachments": [],
            "embeds": [],
            "mentions": [],
            "mention_roles": [],
            "pinned": false,
            "mention_everyone": false,
            "tts": false,
            "timestamp": "2021-12-16T03:16:15.361000+00:00",
            "edited_timestamp": null,
            "flags": 0,
            "components": []
        }
    },
    {
        "id": "920982193789079552",
        "type": 0,
        "content": ".",
        "channel_id": "825437366113271820",
        "author": {
            "id": "294956096353730570",
            "username": "Merry_Binny",
            "avatar": "ac72fa726e522e58a70c77cd7ac1cb5b",
            "discriminator": "0001",
            "public_flags": 64
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T10:14:26.021000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920982172008083457",
        "type": 9,
        "content": "",
        "channel_id": "825437366113271820",
        "author": {
            "id": "294956096353730570",
            "username": "Merry_Binny",
            "avatar": "ac72fa726e522e58a70c77cd7ac1cb5b",
            "discriminator": "0001",
            "public_flags": 64
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T10:14:20.828000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920917196627128320",
        "type": 0,
        "content": "nice",
        "channel_id": "825437366113271820",
        "author": {
            "id": "531532678135283744",
            "username": "Joey",
            "avatar": "7423912d8cbcc9b6270cfa6c504aa2be",
            "discriminator": "0980",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T05:56:09.490000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920876955933499473",
        "type": 0,
        "content": "- whyn- i wanna boost but i canu2019t unboost any server atm",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T03:16:15.361000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920869998858207292",
        "type": 8,
        "content": "",
        "channel_id": "825437366113271820",
        "author": {
            "id": "334067823229796367",
            "username": "cstanze",
            "avatar": "fbaff271566183d1c8b36e57ec13b9e7",
            "discriminator": "1337",
            "public_flags": 128
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T02:48:36.665000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920867024085860362",
        "type": 0,
        "content": ".",
        "channel_id": "825437366113271820",
        "author": {
            "id": "294956096353730570",
            "username": "Merry_Binny",
            "avatar": "ac72fa726e522e58a70c77cd7ac1cb5b",
            "discriminator": "0001",
            "public_flags": 64
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T02:36:47.424000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920867015386857483",
        "type": 0,
        "content": "based color change",
        "channel_id": "825437366113271820",
        "author": {
            "id": "294956096353730570",
            "username": "Merry_Binny",
            "avatar": "ac72fa726e522e58a70c77cd7ac1cb5b",
            "discriminator": "0001",
            "public_flags": 64
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-16T02:36:45.350000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920807771711098880",
        "type": 0,
        "content": "worf true",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-15T22:41:20.557000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920482967053303909",
        "type": 0,
        "content": "based",
        "channel_id": "825437366113271820",
        "author": {
            "id": "262786101037498369",
            "username": "Worf",
            "avatar": "3adbf1cdb94b376b10e1c05ff573d2b8",
            "discriminator": "5035",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-15T01:10:41.092000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920360900966371399",
        "type": 0,
        "content": "bright red",
        "channel_id": "825437366113271820",
        "author": {
            "id": "302477497264504833",
            "username": "not.Ryan",
            "avatar": "da8dfb3dad0b88b996485d8f9fe977f8",
            "discriminator": "2118",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T17:05:38.269000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920360857140084806",
        "type": 0,
        "content": "red",
        "channel_id": "825437366113271820",
        "author": {
            "id": "302477497264504833",
            "username": "not.Ryan",
            "avatar": "da8dfb3dad0b88b996485d8f9fe977f8",
            "discriminator": "2118",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T17:05:27.820000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920332837104783371",
        "type": 0,
        "content": "i rember",
        "channel_id": "825437366113271820",
        "author": {
            "id": "811496735406293062",
            "username": "jaidan",
            "avatar": "a9aef37a86883c423659edec1c89ee02",
            "discriminator": "1111",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T15:14:07.323000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920332830125469766",
        "type": 0,
        "content": "im red",
        "channel_id": "825437366113271820",
        "author": {
            "id": "811496735406293062",
            "username": "jaidan",
            "avatar": "a9aef37a86883c423659edec1c89ee02",
            "discriminator": "1111",
            "public_flags": 256
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T15:14:05.659000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920322917898813502",
        "type": 0,
        "content": "Bsaed",
        "channel_id": "825437366113271820",
        "author": {
            "id": "531532678135283744",
            "username": "Joey",
            "avatar": "7423912d8cbcc9b6270cfa6c504aa2be",
            "discriminator": "0980",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T14:34:42.400000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920300368515190784",
        "type": 0,
        "content": "pink is deprecated basically",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T13:05:06.208000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920300266480365568",
        "type": 0,
        "content": "oh",
        "channel_id": "825437366113271820",
        "author": {
            "id": "294956096353730570",
            "username": "Merry_Binny",
            "avatar": "ac72fa726e522e58a70c77cd7ac1cb5b",
            "discriminator": "0001",
            "public_flags": 64
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T13:04:41.881000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    },
    {
        "id": "920300239607447572",
        "type": 19,
        "content": "ultra based",
        "channel_id": "825437366113271820",
        "author": {
            "id": "645775800897110047",
            "username": "evln",
            "avatar": "a_e1e1528ff058fbe0affe543f1db29b4b",
            "discriminator": "0001",
            "public_flags": 0
        },
        "attachments": [],
        "embeds": [],
        "mentions": [
            {
                "id": "294956096353730570",
                "username": "Merry_Binny",
                "avatar": "ac72fa726e522e58a70c77cd7ac1cb5b",
                "discriminator": "0001",
                "public_flags": 64
            }
        ],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T13:04:35.474000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": [],
        "message_reference": {
            "channel_id": "825437366113271820",
            "guild_id": "825437365027864578",
            "message_id": "920297429654450226"
        },
        "referenced_message": {
            "id": "920297429654450226",
            "type": 0,
            "content": "what is red role",
            "channel_id": "825437366113271820",
            "author": {
                "id": "294956096353730570",
                "username": "Merry_Binny",
                "avatar": "ac72fa726e522e58a70c77cd7ac1cb5b",
                "discriminator": "0001",
                "public_flags": 64
            },
            "attachments": [],
            "embeds": [],
            "mentions": [],
            "mention_roles": [],
            "pinned": false,
            "mention_everyone": false,
            "tts": false,
            "timestamp": "2021-12-14T12:53:25.529000+00:00",
            "edited_timestamp": null,
            "flags": 0,
            "components": []
        }
    },
    {
        "id": "920297429654450226",
        "type": 0,
        "content": "what is red role",
        "channel_id": "825437366113271820",
        "author": {
            "id": "294956096353730570",
            "username": "Merry_Binny",
            "avatar": "ac72fa726e522e58a70c77cd7ac1cb5b",
            "discriminator": "0001",
            "public_flags": 64
        },
        "attachments": [],
        "embeds": [],
        "mentions": [],
        "mention_roles": [],
        "pinned": false,
        "mention_everyone": false,
        "tts": false,
        "timestamp": "2021-12-14T12:53:25.529000+00:00",
        "edited_timestamp": null,
        "flags": 0,
        "components": []
    }
]
""" }

public enum RequestTypes: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

final class DiscordError: Codable {
    var code: Int
    var message: String?
}

func logOut() {
    _ = KeychainManager.save(key: "me.evelyn.accord.token", data: Data())
    NSApp.restart()
}

final class Headers {
    init(userAgent: String? = nil, contentType: String? = nil, token: String? = nil, bodyObject: [String:Any]? = nil, type: RequestTypes, discordHeaders: Bool = false, referer: String? = nil, empty: Bool = false, json: Bool = false, cached: Bool = false) {
        self.userAgent = userAgent
        self.contentType = contentType
        self.token = token
        self.bodyObject = bodyObject
        self.type = type
        self.discordHeaders = discordHeaders
        self.referer = referer
        self.empty = empty
        self.json = json
        self.cached = cached
    }
    var userAgent: String?
    var contentType: String?
    var token: String?
    var bodyObject: [String:Any]?
    var type: RequestTypes
    var discordHeaders: Bool
    var referer: String?
    var empty: Bool?
    var json: Bool
    var cached: Bool
    func set(request: inout URLRequest, config: inout URLSessionConfiguration) throws {
        if let userAgent = self.userAgent {
            config.httpAdditionalHeaders = ["User-Agent": userAgent]
        }
        if cached {
            config.requestCachePolicy = .returnCacheDataElseLoad
        }
        if let contentType = self.contentType, !(self.json) {
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if let token = self.token {
            request.addValue(token, forHTTPHeaderField: "Authorization")
        }
        if self.json {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: self.bodyObject ?? [:], options: [])
        } else if let bodyObject = self.bodyObject {
            if self.type == .GET {
                request.url = request.url?.appendingQueryParameters(bodyObject as? [String:String] ?? [:])
            } else {
                let bodyString = bodyObject.queryParameters
                request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            }
        }
        if self.discordHeaders {
            request.addValue("discord.com", forHTTPHeaderField: ":authority")
            request.addValue("https://discord.com", forHTTPHeaderField: "origin")
            request.addValue("empty", forHTTPHeaderField: "sec-fetch-dest")
            request.addValue("cors", forHTTPHeaderField: "sec-fetch-mode")
            request.addValue("same-origin", forHTTPHeaderField: "sec-fetch-site")
            request.addValue(self.userAgent ?? "WebKit", forHTTPHeaderField: "user-agent")
        }
        if let referer = self.referer {
            request.addValue(referer, forHTTPHeaderField: "referer")
        }

        request.httpMethod = self.type.rawValue
    }
}

var standardHeaders = Headers(
    userAgent: discordUserAgent,
    contentType: nil,
    token: AccordCoreVars.shared.token,
    type: .GET,
    discordHeaders: true,
    referer: "https://discord.com/channels/@me"
)

final public class Request {
    
    // MARK: - Empty Decodable
    struct AnyDecodable: Decodable { }
    
    enum FetchErrors: Error {
        case invalidRequest
        case invalidForm
        case badResponse(URLResponse?)
        case notRequired
        case decodingError(String, Error?)
        case noData
    }
    
    // MARK: - Perform request with completion handler
    class func fetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping ((_ value: T?, _ error: Error?) -> Void)) {
        
        let request: URLRequest? = {
            if let request = request {
                return request
            } else if let url = url {
                return URLRequest(url: url)
            } else {
                print("[Networking] You need to provide a request method")
                return nil
            }
        }()
        guard var request = request else { return completion(nil, FetchErrors.invalidRequest) }
        var config = URLSessionConfiguration.default
        config.setProxy()
        
        // Set headers
        do { try headers?.set(request: &request, config: &config) } catch { return completion(nil, error) }
        
        URLSession(configuration: config).dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data {
                guard error == nil else {
                    print(error?.localizedDescription ?? "Unknown Error")
                    return completion(nil, FetchErrors.badResponse(response))
                }
                if T.self == AnyDecodable.self {
                    return completion(nil, FetchErrors.notRequired) // Bail out if we don't ask for a type
                }
                do {
                    let value = try JSONDecoder().decode(T.self, from: data)
                    return completion(value, nil)
                } catch {
                    guard let error = try? JSONDecoder().decode(DiscordError.self, from: data) else {
                        guard let strError = String(data: data, encoding: .utf8) else { return }
                        return completion(nil, FetchErrors.decodingError(strError, error))
                    }
                    if let message = error.message, message.contains("Unauthorized") {
                        logOut()
                    }
                }
            }
        }).resume()
    }
    
    // MARK: - Perform data request with completion handler
    class func fetch(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil, completion: @escaping ((_ value: Data?, _ error: Error?) -> Void)) {
        
        let request: URLRequest? = {
            if let request = request {
                return request
            } else if let url = url {
                return URLRequest(url: url)
            } else {
                print("[Networking] You need to provide a request method")
                return nil
            }
        }()
        guard var request = request else { return completion(nil, FetchErrors.invalidRequest) }
        var config = URLSessionConfiguration.default
        config.setProxy()
        
        // Set headers
        do { try headers?.set(request: &request, config: &config) } catch { return completion(nil, error) }
        
        URLSession(configuration: config).dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data {
                return completion(data, error)
            }
        }).resume()
    }
    
    // MARK: - fetch() wrapper for empty requests without completion handlers
    class func ping(request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) {
        self.fetch(AnyDecodable.self, request: request, url: url, headers: headers) { _, _ in }
    }
    
    // MARK: - Image getter
    class func image(url: URL?, to size: CGSize? = nil, completion: @escaping ((_ value: NSImage?) -> Void)) {
        guard let url = url else { return completion(nil) }
        let request = URLRequest(url: url)
        if let cachedImage = cache.cachedResponse(for: request) {
            return completion(NSImage(data: cachedImage.data) ?? NSImage())
        }
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data,
                  let imageData = NSImage(data: data)?.downsample(to: size),
                  let image = NSImage(data: imageData) else {
                      print(error?.localizedDescription ?? "unknown error")
                      if let data = data {
                          cache.storeCachedResponse(CachedURLResponse(response: response!, data: data), for: request)
                          return completion(NSImage(data: data))
                      } else {
                          print("load failed")
                          return completion(nil)
                      }
            }
            cache.storeCachedResponse(CachedURLResponse(response: response!, data: imageData), for: request)
            return completion(image)
        }).resume()
    }
    
}

final public class RequestPublisher {
    
    static var EmptyImagePublisher: AnyPublisher<NSImage?, Error> = {
        return Empty<NSImage?, Error>.init().eraseToAnyPublisher()
    }()
    
    // MARK: - Get a publisher for the request
    class func fetch<T: Decodable>(_ type: T.Type, request: URLRequest? = nil, url: URL? = nil, headers: Headers? = nil) -> AnyPublisher<T, Error> {
        
        let request: URLRequest? = {
            if let request = request {
                return request
            } else if let url = url {
                return URLRequest(url: url)
            } else {
                print("[Networking] You need to provide a request method")
                return nil
            }
        }()
        guard var request = request else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
        var config = URLSessionConfiguration.default
        
        // Set headers
        do { try headers?.set(request: &request, config: &config) } catch { return Empty(completeImmediately: true).eraseToAnyPublisher() }

        return URLSession(configuration: config).dataTaskPublisher(for: request)
            .retry(2)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .debugAssertNoMainThread()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Combine Image getter
    class func image(url: URL?, to size: CGSize? = nil) -> AnyPublisher<NSImage?, Error> {
        guard let url = url else { return EmptyImagePublisher }
        let request = URLRequest(url: url)
        if let cachedImage = cache.cachedResponse(for: request) {
            let img = NSImage(data: cachedImage.data)
            return Just.init(img).eraseToAny()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { (data, response) -> NSImage? in
                if let size = size, let downsampled = data.downsample(to: size), let image = NSImage(data: downsampled) {
                    cache.storeCachedResponse(CachedURLResponse(response: response, data: downsampled), for: request)
                    return image
                } else if let image = NSImage(data: data) {
                    cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                    return image
                } else { return nil }
            }
            .debugAssertNoMainThread()
            .eraseToAny()
    }
}

fileprivate extension Data {
    // Thanks Amy :3
    func downsample(to size: CGSize, scale: CGFloat? = nil) -> Data? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) else { return nil }
        let downsampled = self.downsample(source: imageSource, size: size, scale: scale)
        guard let downsampled = downsampled else { return nil }
        return downsampled
    }
    
    private func downsample(source: CGImageSource, size: CGSize, scale: CGFloat?) -> Data? {
        let maxDimensionInPixels = size.width >= 1000 && size.height >= 1000 ? Swift.max(500, 500) : Swift.max(size.width, size.height) * 0.4
        let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceShouldCacheImmediately: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        guard let downScaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampledOptions) else { return nil }
        return downScaledImage.png
    }
}

extension Publisher {
    func eraseToAny() -> AnyPublisher<Self.Output, Error> {
        self.mapError { $0 as Error }.eraseToAnyPublisher()
    }
    func assertNoMainThread() -> Self {
        assert(!Thread.isMainThread)
        return self
    }
    func debugAssertNoMainThread() -> Self {
        #if DEBUG
        assert(!Thread.isMainThread)
        #endif
        return self
    }
}

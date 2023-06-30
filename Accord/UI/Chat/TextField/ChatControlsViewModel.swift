//
//  ChatControlsViewModel.swift
//  Accord
//
//  Created by evelyn on 2022-01-23.
//

import AppKit
import Combine
import Foundation
import SwiftUI
import MachO

final class ChatControlsViewModel: ObservableObject {
    
    @MainActor @Published
    var matchedUsers: [User] = .init()
    
    @MainActor @Published
    var matchedRoles: [String:String] = .init()
    
    @MainActor @Published
    var matchedChannels: [Channel] = .init()
    
    @MainActor @Published
    var matchedEmoji: [DiscordEmote] = .init()
    
    @MainActor @Published
    var matchedCommands: [SlashCommandStorage.Command] = .init()
    
    @MainActor @Published
    var textFieldContents: String = .init()
    
    @MainActor @Published
    var percent: String? = nil
    
    var observation: NSKeyValueObservation?
    var command: SlashCommandStorage.Command?

    var currentValue: String?
    var currentRange: Int?

    @AppStorage("SilentTyping")
    var silentTyping: Bool = false

    var locked: Bool = false
    var runOnUnlock: (() async -> Void)?

    init() {
        if #unavailable(macOS 13.0) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.findView()
            }
        }
    }
    
    @_optimize(speed)
    func checkText(guildID: String, channelID: String) async {
        let ogContents = await textFieldContents
        let mentions = ogContents.matches(precomputed: RegexExpressions.chatTextMentions).map { (str) -> String in
            if str.first == "@" {
                return String(str.dropFirst())
            }
            return str
        }
        let channels = ogContents.matches(precomputed: RegexExpressions.chatTextChannels).map { (str) -> String in
            if str.first == "#" {
                return String(str.dropFirst())
            }
            return str
        }
        let slashes = ogContents.matches(precomputed: RegexExpressions.chatTextSlashCommand).map { (str) -> String in
            if str.first == "/" {
                return String(str.dropFirst())
            }
            return str
        }
        let emoji = ogContents.matches(precomputed: RegexExpressions.chatTextEmoji).map { (str) -> String in
            if str.first == ":" {
                return String(str.dropFirst())
            }
            return str
        }
        let emotes = ogContents.matches(precomputed: RegexExpressions.completedEmote).map { (str) -> String in
            if str.first == ":" {
                return String(str.dropFirst())
            }
            return str
        }

        emotes.forEach { emoji in
            let emote = emoji.dropLast().dropFirst().stringLiteral
            guard let matched: DiscordEmote = Array(Storage.emotes.values.joined()).filter({ $0.name.lowercased() == emote.lowercased() }).first else { return }
            DispatchQueue.main.async {
                if self.textFieldContents != ogContents { return }
                self.textFieldContents = self.textFieldContents.replacingOccurrences(of: emoji, with: "<\((matched.animated ?? false) ? "a" : ""):\(matched.name):\(matched.id)> ")
            }
        }

        guard !ogContents.isEmpty else {
            DispatchQueue.main.async {
                self.matchedEmoji.removeAll()
                self.matchedCommands.removeAll()
                self.matchedUsers.removeAll()
                self.matchedChannels.removeAll()
            }
            return
        }

        if let search = mentions.last?.lowercased() {
            let matchedUsers = Storage.users
                .filterValues { $0.username.lowercased().contains(search.lowercased()) }
                .map(\.value)
            let matchedRoles = Storage.roleNames
                .filterValues { $0.lowercased().contains(search) }
                .mapKeys { "&" + $0 }
            await MainActor.run {
                self.matchedUsers = matchedUsers
                self.matchedRoles = matchedRoles
            }
        } else if let search = channels.last {
            Task.detached {
                let matches = Storage.globals?.folders.map { $0.guilds.compactMap { $0.channels.filter { $0.name?.contains(search) ?? false } } }
                let joined: [Channel] = Array(Array(Array(matches ?? []).joined()).joined())
                    .filter { $0.guild_id == guildID }
                    .prefix(10)
                    .literal()
                DispatchQueue.main.async {
                    self.matchedChannels = joined
                }
            }
        } else if let command = slashes.last?.trimmingCharacters(in: .letters.inverted),
                  ogContents.prefix(1) == "/", guildID != "@me"
        {
            guard !locked else {
                runOnUnlock = { [weak self] in
                    await self?.checkText(guildID: guildID, channelID: channelID)
                }
                return
            }
            locked = true
            print("querying", command)
            let url = URL(string: rootURL)?
                .appendingPathComponent("channels")
                .appendingPathComponent(channelID)
                .appendingPathComponent("application-commands")
                .appendingPathComponent("search")
                .appendingQueryParameters([
                    "type": "1",
                    "query": command,
                    "limit": "7",
                    "include_applications": "true",
                ])
            Request.fetch(
                SlashCommandStorage.GuildApplicationCommandsUpdateEvent.D.self,
                url: url,
                headers: standardHeaders
            ) {
                switch $0 {
                case let .success(commands):
                    DispatchQueue.main.async {
                        self.matchedCommands = commands.application_commands
                    }
                case let .failure(error):
                    print(error)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                self.locked = false
                Task.detached {
                    await self.runOnUnlock?()
                }
            }
        } else if let key = emoji.last {
            let matched = Array(Storage.emotes.values.joined())
                .filter { $0.name.lowercased().contains(key) }
                .prefix(10)
                .literal()
            DispatchQueue.main.async {
                self.matchedEmoji = matched
            }
        }
    }
    
    @MainActor
    func findView() {
        let stop = UnsafeMutablePointer<Bool>.allocate(capacity: MemoryLayout<Bool>.size)
        AppKitLink<NSTextField>(stop).introspect { textField, _ in
            print("found view!!!!")
            textField.lineBreakMode = .byWordWrapping
            textField.usesSingleLineMode = false
            textField.allowsDefaultTighteningForTruncation = true
            textField.lineBreakStrategy = .standard
        }
    }
    
    @MainActor
    func clearMatches() {
        self.matchedUsers.removeAll()
        self.matchedRoles.removeAll()
        self.matchedEmoji.removeAll()
        self.matchedChannels.removeAll()
    }

    func send(text: String, guildID: String, channelID: String) {
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages"), headers: Headers(
            token: Globals.token,
            bodyObject: ["content": text, "tts": false, "nonce": generateFakeNonce()],
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)",
            empty: true,
            json: true
        ))
    }

    func emptyTextField() {
        DispatchQueue.main.async {
            self.textFieldContents = ""
        }
    }

    func executeCommand(guildID: String, channelID: String) async throws {
        guard let command = command else {
            let textFieldContents = await textFieldContents
            if textFieldContents.prefix(6) == "/nick " {
                let nick = textFieldContents.dropFirst(6).stringLiteral
                Request.ping(url: URL(string: "\(rootURL)/guilds/\(guildID)/members/%40me/nick"), headers: Headers(
                    token: Globals.token,
                    bodyObject: ["nick": nick],
                    type: .PATCH,
                    discordHeaders: true,
                    json: true
                ))
                emptyTextField()
            } else if textFieldContents.prefix(6) == "/shrug" {
                send(text: #"¯\_(ツ)_/¯"#, guildID: guildID, channelID: channelID)
                emptyTextField()
            } else if textFieldContents.prefix(6) == "/debug" {
                sendDebugLog(guildID: guildID, channelID: channelID)
                emptyTextField()
            } else if textFieldContents.prefix(6) == "/reset" {
                print(await wss.reset())
                emptyTextField()
            } else if textFieldContents.prefix(12) == "/reset force" {
                wss.hardReset()
                emptyTextField()
            } else if textFieldContents.prefix(5) == "/help" {
                let help = """
                **Slash commands**
                `/shrug`: shrug
                `/debug`: send debug log
                `/reset`: resume websocket connection
                `/reset force`: force reset websocket connection
                """
                let original = Globals.user
                let system = Globals.user
                system?.id = generateFakeNonce()
                system?.username = "Accord"
                system?.discriminator = "0000"
                system?.avatar = nil
                let message = Message(
                    author: system,
                    channelID: channelID,
                    guildID: guildID,
                    content: help,
                    id: generateFakeNonce(),
                    mentions: [],
                    timestamp: .init(),
                    type: .default,
                    attachments: .init(),
                    stickerItems: .init()
                )
                let gatewayMessage = GatewayEventCodable(d: message)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(gatewayMessage)
                wss.messageSubject.send((data, channelID, false))
                Globals.user = original
            }
            return
        }
        var options: [[String: Any]] = []
        if command.options?.count != 0 {
            let args: [(key: String, value: Any)] = await textFieldContents
                .matches(for: #"(\S+):((?:(?! \S+:).)+)"#)
                .compactMap { arg -> (key: String, value: Any)? in
                    let components = arg.components(separatedBy: ":")
                    if let key = components.first, let value = components.last {
                        return (key: key, value: value)
                    } else {
                        return nil
                    }
                }
            options = args.map { arg -> [String: Any] in
                ["name": arg.key, "type": 3, "value": arg.value]
            }
        }

        try SlashCommands.interact(
            applicationID: command.application_id,
            guildID: guildID,
            channelID: channelID,
            appVersion: command.version,
            id: command.id,
            dataType: 1,
            appName: command.name,
            appDescription: command.description,
            options: command.options ?? [],
            optionValues: options
        )

        DispatchQueue.main.async {
            self.command = nil
            self.matchedCommands.removeAll()
            self.emptyTextField()
        }
    }

    let NATIVE_EXECUTION = Int32(0)
    let EMULATED_EXECUTION = Int32(1)
    let UNKONWN_EXECUTION = -Int32(1)
    
    func processIsTranslated() -> Int32 {
        var ret = Int32(0)
        var size = ret.bitWidth
        let result = sysctlbyname("sysctl.proc_translated", &ret, &size, nil, 0)
        return result == -1 ? errno == ENOENT ? 0 : -1 : ret
    }
    
    func processIsTranslatedStr() -> String {
            switch processIsTranslated() {
            case NATIVE_EXECUTION:
                return "Native"
            case EMULATED_EXECUTION:
                return "Rosetta"
            default:
                return "Unknown"
            }
    }
    
    func getArch() -> String? {
        guard let archRaw = NXGetLocalArchInfo().pointee.name else {
            return nil
        }
        return String(cString: archRaw)
    }
    
    var debugLog: String {
        
        """
        **Accord Debug Log**
        macOS Version: \(String(describing: ProcessInfo.processInfo.operatingSystemVersionString))
        Architecture: \(getArch() ?? "Unknown CPU") (\(processIsTranslatedStr()))
        Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
        Gateway State: \(wss.connection?.state as Any)
        Compression: \(wss.compress ? "Enabled" : "Disabled")
        Compressor State: \(wss.decompressor.status.rawValue)
        Connection State: \(reachability?.connection as Any)
        """
    }

    func sendDebugLog(guildID: String, channelID: String) {
        send(text: debugLog, guildID: guildID, channelID: channelID)
    }

    func send(text: String, replyingTo: Message, mention: Bool, guildID: String) {
        Request.ping(url: URL(string: "\(rootURL)/channels/\(replyingTo.channelID)/messages"), headers: Headers(
            token: Globals.token,
            bodyObject: ["content": text, "allowed_mentions": ["parse": ["users", "roles", "everyone"], "replied_user": mention] as [String : Any], "message_reference": ["channel_id": replyingTo.channelID, "message_id": replyingTo.id], "tts": false, "nonce": generateFakeNonce()],
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(replyingTo.channelID)",
            empty: true,
            json: true
        ))
    }

    func send(text: String, file: [URL], data: [Data], channelID: String) {
        var request = URLRequest(url: URL(string: "\(rootURL)/channels/\(channelID)/messages")!)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = Globals.token {
            request.addValue(token, forHTTPHeaderField: "Authorization")
        }
        
        let packet: [String:Any] = file.count > 1 ? [
            "content": text,
            "nonce":generateFakeNonce(),
            "channel_id":channelID,
            "type":0,
            "sticker_ids":[String](),
            "attachments":file.enumerated().map { offset, url in
                [
                    "filename":url.lastPathComponent,
                    "id":offset
                ] as [String : Any]
            }
        ] :
        [
            "content": text,
            "nonce":generateFakeNonce(),
            "channel_id":channelID
        ]
        
        guard let string = try? packet.jsonString() else { return }
        
        print(string)
        
        request.httpBody = try? Request.createMultipartBody(with: string, fileURLs: file.map(\.absoluteString), boundary: boundary, fileData: data)
        print(request.httpBody ?? Data())
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, res, _ in
            if let response = res as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self?.observation = nil
                    self?.percent = nil
                }
            }
        }
        observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.percent = "Uploading \(String(Int(progress.fractionCompleted * 100)))%"
            }
        }
        task.resume()
    }

    func type(channelID: String, guildID: String) {
        guard !silentTyping else { return }
        Request.ping(url: URL(string: rootURL + "/channels/\(channelID)/typing"), headers: Headers(
            token: Globals.token,
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
    }
}

func generateFakeNonce() -> String {
    let date: Double = Date().timeIntervalSince1970
    let nonceNumber = (Int(date) * 1000 - 1_420_070_400_000) * 4_194_304
    return String(nonceNumber)
}

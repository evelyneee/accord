//
//  ChatControlsViewModel.swift
//  Accord
//
//  Created by evelyn on 2022-01-23.
//

import AppKit
import Combine
import Foundation

final class ChatControlsViewModel: ObservableObject {
    @Published var matchedUsers = [User]()
    @Published var matchedChannels = [Channel]()
    @Published var matchedEmoji = [DiscordEmote]()
    @Published var textFieldContents: String = ""
    @Published var cachedUsers = [User]()
    @Published var percent: String? = nil
    var observation: NSKeyValueObservation?

    weak var textField: NSTextField?
    var currentValue: String?
    var currentRange: Int?

    func checkText(guildID: String) {
        let mentions = textFieldContents.matches(for: #"(?<=@)(?:(?!\ ).)*"#)
        let channels = textFieldContents.matches(for: #"(?<=#)(?:(?!\ ).)*"#)
        let slashes = textFieldContents.matches(for: #"(?<=\/)(?:(?!\ ).)*"#)
        let emoji = textFieldContents.matches(for: #"(?<=:).*"#)
        if let search = mentions.first {
            let matched = cachedUsers.filter { $0.username.lowercased().contains(search.lowercased()) }
            DispatchQueue.main.async {
                self.matchedUsers = matched.removingDuplicates()
            }
        } else if let search = channels.first {
            let matches = ServerListView.folders.map { $0.guilds.compactMap { $0.channels?.filter { $0.name?.contains(search) ?? false } } }
            let joined: [Channel] = Array(Array(Array(matches).joined()).joined()).filter { $0.guild_id == guildID }
            DispatchQueue.main.async {
                self.matchedChannels = joined
            }
        } else if !(slashes.isEmpty) {
            // TODO: Slash command implementation here
        } else if let key = emoji.first {
            let matched: [DiscordEmote] = Array(Emotes.emotes.values.joined()).filter { $0.name.lowercased().contains(key) }
            DispatchQueue.main.async {
                self.matchedEmoji = matched
            }
        }
    }

    func findView() {
        AppKitLink<NSTextField>.introspect { [weak self] textField, _ in
            textField.allowsEditingTextAttributes = true
            self?.textField = textField
        }
    }

    func markdown() {
        guard !textFieldContents.isEmpty else { return }
        textField?.allowsEditingTextAttributes = true
        let attributed = NSAttributedMarkdown.markdown(textFieldContents, font: textField?.font)
        textField?.attributedStringValue = attributed
        let emotes = textFieldContents.matches(for: "(?<!<|<a):.+:")
        emotes.forEach { emoji in
            let emote = emoji.dropLast().dropFirst().stringLiteral
            guard let matched: DiscordEmote = Array(Emotes.emotes.values.joined()).filter({ $0.name.lowercased() == emote.lowercased() }).first else { return }
            textFieldContents = textFieldContents.replacingOccurrences(of: emoji, with: "<\((matched.animated ?? false) ? "a" : ""):\(matched.name):\(matched.id)>")
        }
    }

    func send(text: String, guildID: String, channelID: String) {
        DispatchQueue.main.sync {
            self.textFieldContents = ""
        }
        DispatchQueue.main.async {
            // self.textField?.becomeFirstResponder()
            // self.textField?.allowsEditingTextAttributes = true
        }
        Request.ping(url: URL(string: "\(rootURL)/channels/\(channelID)/messages"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            bodyObject: ["content": text],
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)",
            empty: true,
            json: true
        ))
    }

    func send(text: String, replyingTo: Message, mention: Bool, guildID: String) {
        DispatchQueue.main.sync {
            self.textFieldContents = ""
        }
        DispatchQueue.main.async {
            // self.textField?.becomeFirstResponder()
            // self.textField?.allowsEditingTextAttributes = true
        }
        Request.ping(url: URL(string: "\(rootURL)/channels/\(replyingTo.channel_id)/messages"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            bodyObject: ["content": text, "allowed_mentions": ["parse": ["users", "roles", "everyone"], "replied_user": mention], "message_reference": ["channel_id": replyingTo.channel_id, "message_id": replyingTo.id]],
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(replyingTo.channel_id)",
            empty: true,
            json: true
        ))
    }

    func send(text: String, file: URL, data: Data, channelID: String) {
        DispatchQueue.main.sync {
            self.textFieldContents = ""
        }
        DispatchQueue.main.async {
            // self.textField?.becomeFirstResponder()
            // self.textField?.allowsEditingTextAttributes = true
        }
        var request = URLRequest(url: URL(string: "\(rootURL)/channels/\(channelID)/messages")!)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let params: [String: String] = [
            "content": String(text),
        ]
        request.addValue(AccordCoreVars.token, forHTTPHeaderField: "Authorization")
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        for key in params.keys {
            body.append(string: boundaryPrefix, encoding: .utf8)
            body.append(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n", encoding: .utf8)
            body.append(string: "\(params["content"]!)\r\n", encoding: .utf8)
        }
        body.append(string: boundaryPrefix, encoding: .utf8)
        let mimeType = file.mimeType()
        body.append(string: "Content-Disposition: form-data; name=\"file\"; filename=\"\(file.pathComponents.last ?? "file.txt")\"\r\n", encoding: .utf8)
        body.append(string: "Content-Type: \(mimeType) \r\n\r\n", encoding: .utf8)
        body.append(data)
        body.append(string: "\r\n", encoding: .utf8)
        body.append(string: "--".appending(boundary.appending("--")), encoding: .utf8)
        request.httpBody = body
        let task = URLSession.shared.dataTask(with: request)
        DispatchQueue.main.async {
            self.observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                print("updating")
                DispatchQueue.main.async {
                    self?.percent = "Uploading \(String(Int(progress.fractionCompleted * 100)))%"
                    if task.progress.isFinished {
                        self?.observation = nil
                        self?.percent = nil
                    }
                }
            }
        }
        task.resume()
    }

    func type(channelID: String, guildID: String) {
        Request.ping(url: URL(string: "https://discord.com/api/v9/channels/\(channelID)/typing"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            type: .POST,
            discordHeaders: true,
            referer: "https://discord.com/channels/\(guildID)/\(channelID)"
        ))
    }
}

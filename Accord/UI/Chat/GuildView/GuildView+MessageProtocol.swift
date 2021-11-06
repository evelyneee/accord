//
//  GuildView+MessageProtocol.swift
//  GuildView+MessageProtocol
//
//  Created by evelyn on 2021-08-23.
//

import Foundation

extension GuildView: MessageControllerDelegate {
    func sendMessage(msg: Data, channelID: String?) {
        // Received a message from backend
        webSocketQueue.async {
            guard channelID != nil else { return }
            if channelID! == self.channelID {
                sending = false
                guard let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: msg) else { return }
                guard let message = gatewayMessage.d else { return }
                message.lastMessage = viewModel.messages.first
                DispatchQueue.main.async {
                    self.popup.append(false)
                    message.isSameAuthor() ? print("No pfp to store") : message.author?.loadPfp()
                    viewModel.messages.insert(message, at: 0)
                }
            }
        }
    }
    func editMessage(msg: Data, channelID: String?) {
        // Recieved a message from backend
        webSocketQueue.async {
            if channelID == self.channelID {
                guard channelID != nil else { return }
                if channelID! == self.channelID {
                    guard let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: msg) else { return }
                    guard let message = gatewayMessage.d else { return }
                    guard let index = fastIndexMessage(message.id, array: viewModel.messages) else { return }
                    DispatchQueue.main.async {
                        viewModel.messages[index].content = message.content
                    }
                }
            }

        }
    }
    func deleteMessage(msg: Data, channelID: String?) {
        if channelID == self.channelID {
            webSocketQueue.async {
                guard let gatewayMessage = try? JSONDecoder().decode(GatewayDeletedMessage.self, from: msg) else { return }
                guard let message = gatewayMessage.d else { return }
                guard let index = fastIndexMessage(message.id, array: viewModel.messages) else { return }
                DispatchQueue.main.async {
                    viewModel.messages.remove(at: index)
                }
            }
        }
    }
    func typing(msg: [String: Any], channelID: String?) {
        webSocketQueue.async {
            if channelID == self.channelID {
                if !(typing.contains(msg["user_id"] as? String ?? "")) {
                    guard let memberData = try? JSONSerialization.data(withJSONObject: msg, options: []) else { return }
                    guard let memberDecodable = try? JSONDecoder().decode(TypingEvent.self, from: memberData) else { return }
                    dump(memberDecodable)
                    guard let nick_fake = viewModel.nicks[memberDecodable.user_id ?? ""] else {
                        guard let nick = memberDecodable.member?.nick else {
                            typing.append(memberDecodable.member?.user.username ?? "")
                            DispatchQueue.global().asyncAfter(deadline: .now() + 7, execute: {
                                typing.remove(at: typing.firstIndex(of: memberDecodable.member?.user.username ?? "Unknown User") ?? 0)
                            })
                            return
                        }
                        typing.append(nick)
                        DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
                            typing.remove(at: typing.firstIndex(of: (nick)) ?? 0)
                        })
                        return
                    }
                    typing.append(nick_fake)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
                        typing.remove(at: typing.firstIndex(of: (nick_fake)) ?? 0)
                    })
                }
            }

        }

    }
    func sendMemberChunk(msg: Data) {
        webSocketQueue.async {
            guard let chunk = try? JSONDecoder().decode(GuildMemberChunkResponse.self, from: msg) else { return }
            guard let users = chunk.d?.members else { return }
            ChannelMembers.shared.channelMembers[self.channelID] = Dictionary(uniqueKeysWithValues: zip(users.compactMap { $0!.user.id }, users.compactMap { $0?.nick ?? $0!.user.username }))
            for person in users {
                wss.cachedMemberRequest["\(guildID)$\(person?.user.id ?? "")"] = person
                let nickname = person?.nick ?? person?.user.username ?? ""
                DispatchQueue.main.async {
                    viewModel.nicks[(person?.user.id ?? "")] = nickname
                }
                var rolesTemp: [String] = Array.init(repeating: "", count: 100)
                for role in (person?.roles ?? []) {
                    rolesTemp[roleColors[role]?.1 ?? 0] = role
                }
                rolesTemp = rolesTemp.compactMap { role -> String? in
                    if role == "" {
                        return nil
                    } else {
                        return role
                    }
                }.reversed()
                DispatchQueue.main.async {
                    viewModel.roles[(person?.user.id ?? "")] = (rolesTemp.indices.contains(0) ? rolesTemp[0] : "")
                }
            }
            viewModel.processRoleColors(roles: viewModel.roles)
        }
    }
    func sendWSError(msg: String) {
        error = msg
    }
}

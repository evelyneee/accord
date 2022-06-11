//
//  NewInviteSheet.swift
//  Accord
//
//  Created by evelyn on 2022-05-19.
//

import AppKit
import Foundation
import SwiftUI

struct NewInviteSheet: View {
    @State var code: String?
    @State var errorText: String? = nil
    @Binding var selection: Int?
    @Binding var isPresented: Bool
    @State var maxAge: Int = 0
    @State var maxUses: Int = 0
    let desc: NSWindow.PersistableFrameDescriptor? = nil

    var ageString: String {
        if maxAge == 0 {
            return "Never"
        } else if maxAge == 1800 {
            return "30 minutes"
        } else if maxAge <= 43200 {
            return String(maxAge / 60 / 60) + " hours"
        } else {
            return String(maxAge / 60 / 60 / 24) + " days"
        }
    }

    var maxUsesString: String {
        switch maxUses {
        case 0: return "No limit"
        case 1: return "1 use"
        case 5: return "5 uses"
        case 10: return "10 uses"
        case 25: return "25 uses"
        case 50: return "50 uses"
        case 100: return "100 uses"
        default: maxUses = 0; return "No limit"
        }
    }

    var body: some View {
        VStack {
            Text("Create a new invite")
                .font(.title)
                .fontWeight(.bold)
            if let code = code {
                HStack {
                    HStack(spacing: 0) {
                        Text("Invite Code: ")
                            .fontWeight(.medium)
                        Text("https://discord.gg/" + code)
                            .fontWeight(.medium)
                            .textSelection(.enabled)
                    }
                    .padding(5)
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("https://discord.gg/" + (self.code ?? ""), forType: .string)
                    }
                }
            }
        }

        Menu("Expires in " + self.ageString) {
            Button("30 minutes") {
                self.maxAge = 30 * 60
            }
            Button("1 hour") {
                self.maxAge = 60 * 60
            }
            Button("6 hours") {
                self.maxAge = 60 * 60 * 6
            }
            Button("12 hours") {
                self.maxAge = 60 * 60 * 12
            }
            Button("1 day") {
                self.maxAge = 60 * 60 * 24
            }
            Button("7 days") {
                self.maxAge = 60 * 60 * 24 * 7
            }
            Button("Never") {
                self.maxAge = 0
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)

        Menu(self.maxUsesString) {
            Button("No limit") {
                self.maxUses = 0
            }
            Button("1 use") {
                self.maxUses = 1
            }
            Button("5 uses") {
                self.maxUses = 5
            }
            Button("10 uses") {
                self.maxUses = 10
            }
            Button("25 uses") {
                self.maxUses = 25
            }
            Button("50 uses") {
                self.maxUses = 50
            }
            Button("100 uses") {
                self.maxUses = 100
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)

        if let errorText = errorText {
            Text(errorText)
                .foregroundColor(.red)
        }

        HStack {
            Button("Dismiss") {
                isPresented.toggle()
            }
            .controlSize(.large)
            .onExitCommand {
                isPresented.toggle()
            }

            Button("Generate new invite") {
                self.generateCode()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        }
    }

    func generateCode() {
        guard let selection = selection else {
            return
        }
        let url = URL(string: rootURL)?
            .appendingPathComponent("channels")
            .appendingPathComponent(String(selection))
            .appendingPathComponent("invites")
        Request.fetch(InviteUpdate.self, url: url, headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            bodyObject: ["max_age": maxAge,
                         "max_uses": maxUses,
                         "target_type": NSNull(),
                         "validate": NSNull(),
                         "temporary": maxAge == 0],
            type: .POST,
            discordHeaders: true,
            json: true
        )) {
            switch $0 {
            case let .success(update):
                print(update, ["max_age": self.maxAge,
                               "max_uses": self.maxUses,
                               "target_type": NSNull(),
                               "validate": NSNull(),
                               "temporary": self.maxAge == 0])
                self.code = update.code
            case let .failure(error):
                print(error)
            }
        }
    }
}

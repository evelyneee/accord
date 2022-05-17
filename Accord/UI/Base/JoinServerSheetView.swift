//
//  JoinServerSheetView.swift
//  Accord
//
//  Created by Serena on 18/05/2022
//
	

import SwiftUI

struct JoinServerSheetView: View {
    @State var inviteCode: String = ""
    @State var errorText: String? = nil
        
    @Binding var isPresented: Bool
    @StateObject var updater: ServerListView.UpdateView
    var body: some View {
        VStack {
            Text("Join a server")
                .font(.title3)
                .fontWeight(.bold)
            
            TextField("Invite Code", text: $inviteCode)
                .textFieldStyle(.roundedBorder)
                .onExitCommand {
                    isPresented.toggle()
                }
            Text("ie: `zun3eCEr6k`")
                .font(.subheadline)
        }
        
        if let errorText = errorText {
            Text(errorText)
                .foregroundColor(.red)
        }
        
        HStack {
            Button("Dismiss") {
                isPresented.toggle()
            }
            .controlSize(.large)
            
            Button("Join") {
                inviteCode = inviteCode.replacingOccurrences(of: "discord.gg/", with: "")
                inviteCode = inviteCode.replacingOccurrences(of: "https://discord.gg/", with: "")
                joinServer()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        }
    }
    
    func joinServer() {
        guard !inviteCode.isEmpty else {
            errorText = "Invite Code must not be empty"
            return
        }

        let joinURL = URL(string: rootURL)!
            .appendingPathComponent("invites")
            .appendingPathComponent(inviteCode)
        Request.fetch(request: nil, url: joinURL, headers: .init(userAgent: discordUserAgent, token: AccordCoreVars.token, bodyObject: nil, type: .POST, discordHeaders: true, cached: false)) { result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                if let discordError = try? decoder.decode(DiscordError.self, from: data) {
                    errorText = "Error: \(discordError.message ?? "Unknown Error")"
                    return
                }
                
                isPresented.toggle()
                updater.updateView()
            case .failure(let err):
                errorText = "Error: \(err.localizedDescription)"
                print("error: \(err)")
            }
        }
    }
}

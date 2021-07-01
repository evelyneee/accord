//
//  ProfileView.swift
//  Accord
//
//  Created by evelyn on 2020-11-28.
//

import SwiftUI

struct ProfileView: View {
    @State public var showingDetail = false
    @Environment(\.openURL) var openURL
    @State var referenceLinks: [String: String] = [:]
    @State var profileData: Data? = Data()
    @State var profile: [String:Any] = [:]
    private var columns: [GridItem] = [
        GridItem(.fixed(100), spacing: 16),
        GridItem(.fixed(100), spacing: 16),
        GridItem(.fixed(100), spacing: 16)
    ]
    var body: some View {
//        profile views
        
        VStack {
            HStack(alignment: .top) {
//                pfp
                if let imageURL = "https://cdn.discordapp.com/avatars/\(profile["id"] as? String ?? "")/\(profile["avatar"] as? String ?? "").png?size=256" {
                    ImageWithURL(imageURL)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                } else {
                    Color.gray
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .frame(width: 50, height: 50)
                        .padding(.trailing, 6.0)
                }
                
//                bio/description
                
                VStack(alignment: .leading) {
                    Text(profile["username"] as? String ?? "")
                        .fontWeight(.bold)
                        .font(.title2)
                    Text("Email: \(profile["email"] as? String ?? "")")

                }
                Spacer()
                Button(action: {
                    self.showingDetail.toggle()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title)
                        .padding()
                }.sheet(isPresented: $showingDetail) {
                    SettingsView()
                }
                .buttonStyle(CoolButtonStyle())
            }
            .padding()
            Button(action: {
                _ = KeychainManager.save(key: "token", data: String("").data(using: String.Encoding.utf8) ?? Data())
            }) {
                Text("log out")
            }
            Spacer()
        }.onAppear {
            NetworkHandling.shared?.requestData(url: "\(rootURL)/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                if (completion) {
                    profileData = data
                    profile = try! JSONSerialization.jsonObject(with: profileData ?? Data(), options: []) as? [String:Any] ?? [String:Any]()
                    user_id = profile["id"] as? String ?? ""
                    NetworkHandling.shared?.requestData(url: "https://cdn.discordapp.com/avatars/\(profile["id"] as? String ?? "")/\(profile["avatar"] as? String ?? "").png?size=256", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() } }
                }
            }
        }
    }
}




struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

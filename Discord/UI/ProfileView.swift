//
//  ProfileView.swift
//  Helselia
//
//  Created by evelyn on 2020-11-28.
//

import SwiftUI

struct ProfileView: View {
    @State public var showingDetail = false
    @Environment(\.openURL) var openURL
    @State var referenceLinks: [String: String] = [:]
    @State var profileData: Data? = Data()
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
                if let imageURL = "https://cdn.discordapp.com/avatars/\(ProfileManager.shared.getSelfProfile(key: "id", data: profileData)[safe: 0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar", data: profileData)[safe: 0]  as? String ?? "").png?size=80" {
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
                    if ProfileManager.shared.getSelfProfile(key: "verified", data: profileData)[safe: 0] as? Bool == true {
                        Text("\(ProfileManager.shared.getSelfProfile(key: "username", data: profileData)[safe: 0] as? String ?? "") 􀇻")
                            .fontWeight(.bold)
                            .font(.title2)
                    } else {
                        Text(ProfileManager.shared.getSelfProfile(key: "username", data: profileData)[safe: 0] as? String ?? "")
                            .fontWeight(.bold)
                            .font(.title2)
                    }
                    Text("Email: \(ProfileManager.shared.getSelfProfile(key: "email", data: profileData)[safe: 0] as? String ?? "")")
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
                    
            .padding()
            Button(action: {
                UserDefaults.standard.set("", forKey: "token")
            }) {
                Text("log out")
            }
            
            LazyVGrid(columns: columns, alignment: .center) {
                ForEach(referenceLinks.sorted(by: >), id: \.key) { key, link in
                    Button(action: {
                        guard let url = URL(string: referenceLinks[key] ?? "") else { return }
                        openURL(url)
                    }, label: {
                        HStack {
                            Image(systemName: "link")
                            Divider()
                            Text(key)
                        }
                    })
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding()
            
            Spacer()
        }.onAppear {
            net.requestData(url: "\(rootURL)/users/@me", token: token, json: false, type: .GET, bodyObject: [:]) { completion, data in
                if (completion) {
                    profileData = data
                    user_id = ProfileManager.shared.getSelfProfile(key: "id", data: profileData)[safe: 0]  as? String ?? ""
                    net.requestData(url: "https://cdn.discordapp.com/avatars/\(ProfileManager.shared.getSelfProfile(key: "id", data: profileData)[safe: 0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar", data: profileData)[safe: 0]  as? String ?? "").png?size=80", token: token, json: false, type: .GET, bodyObject: [:]) { success, data in if success { avatar = data ?? Data() }}
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
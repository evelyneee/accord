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
                if let imageURL = "https://cdn.constanze.live/avatars/\(ProfileManager.shared.getSelfProfile(key: "id")[0]  as? String ?? "")/\(ProfileManager.shared.getSelfProfile(key: "avatar")[0]  as? String ?? "").png" {
                    ImageWithURL(imageURL)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                } else {
                    Image("pfp").resizable()
                        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .padding(.trailing, 6.0)
                }

                
//                bio/description
                
                VStack(alignment: .leading) {
                    Text(ProfileManager.shared.getSelfProfile(key: "username")[0] as? String ?? "")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .font(.title2)
                    Text("Email: \(ProfileManager.shared.getSelfProfile(key: "email")[0] as? String ?? "")")
                }
                Spacer()
                Button(action: {
                    refLinks = referenceLinks
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
            
//            stats view
            
            VStack(alignment: .leading) {
                Text("My Stats")
                    .font(.title2)
                    .fontWeight(.bold)
                List {
                    Text("Joined: December 2020")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Open Issues: \(issueContainer.count)")
                        .fontWeight(.bold)
                        .font(.title3)
                    Text("Total Issues: \(totalIssues)")
                        .fontWeight(.bold)
                        .font(.title3)
                }
            }
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
            referenceLinks = refLinks
        }
    }
}




struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

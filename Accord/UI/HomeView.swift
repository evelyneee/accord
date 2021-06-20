//
//  HomeView.swift
//  Accord
//
//  Created by Évelyne Bélanger on 2020-12-20.
//

import SwiftUI

struct HomeView: View {
    @State var topics: [[String: String]] = [["name": "Tabs", "imageName": "FeaturedTab"], ["name": "List Views", "imageName": "listviews"]]
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text("Featured")
                    .fontWeight(.bold)
                    .font(.title)
                    .padding()
                Spacer()
            }
            HStack(alignment: .top, spacing: 20) {
                ForEach(topics, id: \.self) { topic in
                    TopicTabs(image: topic["imageName"]!, name: topic["name"]!)
                }
            }
            Spacer()
        }
    }
}

struct TopicTabs: View {
    var image: String
    var name: String
    @State var hovering: Bool = false
    var body: some View {
        ZStack {
            Image(image).resizable()
                .frame(width: 150 + (hovering ? 20 : 0), height: 150 + (hovering ? 20 : 0))
                .scaledToFit()
            LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .bottom, endPoint: .top)
            HStack(alignment: .top) {
                Spacer()
                VStack(alignment: .leading) {
                    Spacer()
                    Text(name)
                        .foregroundColor(Color.white)
                        .fontWeight(.bold)
                        .padding()
                        .font(.title)
                }
            }

        }
        .cornerRadius(hovering ? 18 : 15)
        .shadow(radius: 5)
        .padding(.leading, 65)
        .frame(width: 150, height: 150)
        .animation(.easeIn(duration: 0.13))
        .onHover(perform: { hovering in
            self.hovering = hovering
        })
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

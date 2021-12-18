//
//  PopoverProfileView.swift
//  Accord
//
//  Created by evelyn on 2021-07-13.
//

import SwiftUI

struct PopoverProfileView: View {
    @Binding var user: User?
    @State var hovered: Int? = nil
    @State var pfp: Attachment = {
        Attachment("")
    }()
    var body: some View {
        return ZStack(alignment: .top) {
            VStack {
                Color(pfp.imageLoader.image.averageColor ?? NSColor.windowBackgroundColor).frame(height: 100).opacity(0.75)
                Spacer()
            }
            VStack {
                Spacer().frame(height: 100)
                VStack(alignment: .leading) {
                    pfp
                        .equatable()
                        .clipShape(Circle())
                        .frame(width: 45, height: 45)
                        .shadow(radius: 5)
                    Text(user?.username ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(user?.username ?? "")#\(user?.discriminator ?? "")")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                    HStack(alignment: .bottom) {
                        Button(action: {
                            
                        }, label: {
                            VStack {
                                Image(systemName: "bubble.right.fill")
                                    .imageScale(.medium)
                                Text("Message")
                                    .font(.subheadline)
                            }
                            .padding(4)
                            .frame(width: 60, height: 45)
                            .background(hovered == 1 ? Color.gray.opacity(0.25).cornerRadius(5) : Color.clear.cornerRadius(5))
                        })
                            .buttonStyle(BorderlessButtonStyle())
                            .onHover(perform: { hover in
                                switch hover {
                                case true:
                                    withAnimation {
                                        hovered = 1
                                    }
                                case false:
                                    withAnimation {
                                        hovered = nil
                                    }
                                }
                            })
                        Button(action: {
                            
                        }, label: {
                            VStack {
                                Image(systemName: "phone.fill")
                                    .imageScale(.large)
                                Text("Call")
                                    .font(.subheadline)
                            }
                            .padding(4)
                            .frame(width: 60, height: 45)
                            .background(hovered == 2 ? Color.gray.opacity(0.25).cornerRadius(5) : Color.clear.cornerRadius(5))
                        })
                            .buttonStyle(BorderlessButtonStyle())
                            .onHover(perform: { hover in
                                switch hover {
                                case true:
                                    withAnimation {
                                        hovered = 2
                                    }
                                case false:
                                    withAnimation {
                                        hovered = nil
                                    }
                                }
                            })
                        Button(action: {
                            
                        }, label: {
                            VStack {
                                Image(systemName: "camera.circle.fill")
                                    .imageScale(.large)
                                Text("Video call")
                                    .font(.subheadline)
                            }
                            .padding(4)
                            .frame(width: 60, height: 45)
                            .background(hovered == 3 ? Color.gray.opacity(0.25).cornerRadius(5) : Color.clear.cornerRadius(5))
                        })
                            .buttonStyle(BorderlessButtonStyle())
                            .onHover(perform: { hover in
                                switch hover {
                                case true:
                                    withAnimation {
                                        hovered = 3
                                    }
                                case false:
                                    withAnimation {
                                        hovered = nil
                                    }
                                }
                            })
                        Button(action: {
                            
                        }, label: {
                            VStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .imageScale(.large)
                                Text("Add Friend")
                                    .font(.subheadline)
                            }
                            .padding(4)
                            .frame(width: 60, height: 45)
                            .background(hovered == 4 ? Color.gray.opacity(0.25).cornerRadius(5) : Color.clear.cornerRadius(5))
                        })
                            .buttonStyle(BorderlessButtonStyle())
                            .onHover(perform: { hover in
                                switch hover {
                                case true:
                                    withAnimation {
                                        hovered = 4
                                    }
                                case false:
                                    withAnimation {
                                        hovered = nil
                                    }
                                }
                            })
                    }
                    .transition(AnyTransition.opacity)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(width: 290, height: 250)
        .onAppear {
            self.pfp = Attachment(pfpURL(user?.id, user?.avatar))
        }
    }
}

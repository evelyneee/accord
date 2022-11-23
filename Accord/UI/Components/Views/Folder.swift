//
//  Folder.swift
//  Accord
//
//  Created by evelyn on 2022-07-06.
//

import SwiftUI

struct Folder<Content: View>: View {
    internal init(icon: [Guild], color: Color, read: Bool, mentionCount: Int? = nil, content: @escaping () -> Content) {
        self.icon = icon
        self.color = color
        self.read = read
        self.mentionCount = mentionCount
        self.content = content
        self._collapsed = .init(wrappedValue: true, "Collapsed\(icon.map(\.id).joined())")
    }
    
    
    var icon: [Guild]
    var color: Color
    var read: Bool
    var mentionCount: Int?
    var content: () -> Content

    @AppStorage private var collapsed: Bool

    let gridLayout: [GridItem] = GridItem.multiple(count: 2, spacing: 0)

    var body: some View {
        VStack {
            Button(
                action: { withAnimation(Animation.easeInOut(duration: 0.1)) { self.collapsed.toggle() } },
                label: {
                    HStack {
                        Circle()
                            .fill()
                            .foregroundColor(Color.primary)
                            .frame(width: 5, height: 5)
                            .opacity(read && collapsed ? 1 : 0)
                        if self.collapsed {
                            ZStack(alignment: .bottomTrailing) {
                                VStack(spacing: 3) {
                                    HStack(spacing: 3) {
                                        FolderIcon(guild: icon.first)
                                        FolderIcon(guild: icon[safe: 1])
                                    }
                                    HStack(spacing: 3) {
                                        FolderIcon(guild: icon[safe: 2])
                                        FolderIcon(guild: icon[safe: 3])
                                    }
                                }
                                .frame(width: 45, height: 45)
                                .background(color.opacity(0.75))
                                .cornerRadius(15)
                                .frame(width: 45, height: 45)
                                .redBadge(collapsed ? .constant(mentionCount) : .constant(nil))
                            }
                        } else {
                            if #available(macOS 13.0, *) {
                                #if canImport(WeatherKit)
                                Image(systemName: "folder.fill")
                                    .font(.title2)
                                    .foregroundColor(color.lighter().opacity(0.75))
                                    .padding()
                                    .frame(width: 45, height: 45)
                                    .background(color.opacity(0.65).gradient)
                                    .cornerRadius(15)
                                    .frame(width: 45, height: 45)
                                #else
                                Image(systemName: "folder.fill")
                                    .font(.title2)
                                    .foregroundColor(color.lighter().opacity(0.75))
                                    .padding()
                                    .frame(width: 45, height: 45)
                                    .background(color.opacity(0.65))
                                    .cornerRadius(15)
                                    .frame(width: 45, height: 45)
                                #endif
                            } else {
                                Image(systemName: "folder.fill")
                                    .font(.title2)
                                    .foregroundColor(color.lighter().opacity(0.75))
                                    .padding()
                                    .frame(width: 45, height: 45)
                                    .background(color.opacity(0.65))
                                    .cornerRadius(15)
                                    .frame(width: 45, height: 45)
                            }
                        }
                    }
                }
            )
            .buttonStyle(.plain)
            VStack {
                if !collapsed {
                    self.content()
                }
            }
        }
        .frame(width: 45)
    }
}


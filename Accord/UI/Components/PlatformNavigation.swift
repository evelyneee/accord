//
//  PlatformNavigation.swift
//  Accord
//
//  Created by evelyn on 2022-10-08.
//

import SwiftUI

struct PlatformNavigationView<Sidebar: View, Detail: View>: View {
    
    @ViewBuilder var sidebar: () -> Sidebar
    @ViewBuilder var detail: () -> Detail
    
    @ViewBuilder
    var body: some View {
        if #available(macOS 13.0, *) {
            NavigationSplitView {
                sidebar()
            } detail: {
                detail()
            }
        } else {
            NavigationView(content: sidebar)
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
        }
    }
}


struct PlatformNavigationLink<Destination: View>: View {
    
    var item: Channel
    @Binding var selection: Channel?
    
    @ViewBuilder var destination: () -> Destination
    
    @ViewBuilder
    var body: some View {
        
        if #available(macOS 13.0, *) {
            NavigationLink(value: self.item, label: {
                ServerListViewCell(channel: .constant(item))
            })
        } else {
            NavigationLink (
                tag: item,
                selection: $selection,
                destination: destination, label: { ServerListViewCell(channel: .constant(item)) })

        }
    }
}

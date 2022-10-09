//
//  PlatformNavigation.swift
//  Accord
//
//  Created by evelyn on 2022-10-08.
//

import SwiftUI

struct PlatformNavigationView<Sidebar: View, Detail: View>: View {
    
    var sidebar: () -> Sidebar
    var detail: () -> Detail
    
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

struct PlatformNavigationList<SelectionValue: Hashable, Content: View>: View {
    
    var selection: Binding<SelectionValue>
    var content: () -> Content
        
    init(
        selection: Binding<SelectionValue>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.selection = selection
        self.content = content
    }
    
    @ViewBuilder
    var body: some View {
        if #available(macOS 13.0, *) {
            List(selection: selection, content: content)
        } else {
            List(content: content)
        }
    }
}


struct PlatformNavigationLink<Destination: View, Label: View>: View {
    
    var item: Channel
    @Binding var selection: Channel?
    
    var destination: () -> Destination
    var label: () -> Label
    
    @ViewBuilder
    var body: some View {
        if #available(macOS 13.0, *) {
            label()
        } else {
            NavigationLink (
                tag: item,
                selection: $selection,
                destination: destination, label: label)

        }
    }
}

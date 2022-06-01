//
//  MatchElementView.swift
//  Accord
//
//  Created by evelyn on 2022-05-31.
//

import SwiftUI

struct MatchesView<Data: RangeReplaceableCollection & RandomAccessCollection & MutableCollection, Content: View, ID: Hashable>: View {
    var elements: Data
    var id: KeyPath<Data.Element, ID>
    var action: ((Data.Element) -> Void)
    var label: ((Data.Element) -> Content)
    var body: some View {
        ForEach(elements, id: id) { element in
            Button(action: {
                action(element)
            }, label: {
                label(element)
            })
            .buttonStyle(.borderless)
            .padding(3)
        }
    }
}

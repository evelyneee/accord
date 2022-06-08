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
            if let element = element as AnyObject {
                Button(action: { [weak element] in
                    guard let element = element as? Data.Element else { return }
                    action(element)
                }, label: { [weak element] in
                    if let element = element as? Data.Element {
                        label(element)
                    }
                })
                .buttonStyle(.borderless)
                .padding(3)
            }
        }
    }
}

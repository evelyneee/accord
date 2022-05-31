//
//  GridStack.swift
//  Accord
//
//  Created by evelyn on 2022-05-30.
//

import SwiftUI

struct GridStack<T: Identifiable, Content: View>: View {
    let rows: Int?
    let columns: Int?
    let verticalAlignment: SwiftUI.HorizontalAlignment
    let horizontalAlignment: SwiftUI.VerticalAlignment
    let array: [T]
    let content: (T) -> Content

    init(_ array: [T], rowAlignment: SwiftUI.HorizontalAlignment = .center, columnAlignment: SwiftUI.VerticalAlignment = .center, rows: Int? = nil, columns: Int? = nil, @ViewBuilder content: @escaping (T) -> Content) {
        self.array = array
        self.verticalAlignment = rowAlignment
        self.horizontalAlignment = columnAlignment
        self.rows = rows
        self.columns = columns
        self.content = content
    }
    
    @ViewBuilder
    var body: some View {
        if let rows = rows {
            VStack(alignment: self.verticalAlignment) {
                ForEach(0 ..< rows, id: \.self) { row in
                    HStack(alignment: self.horizontalAlignment) {
                        ForEach(0 ..< Int(round(Double(array.count / rows))), id: \.self) { column in
                            content(self.array[row*column])
                                .id(self.array[row*column].id)
                                .onAppear { print(self.array[row*column].id) }
                        }
                    }
                    .id(UUID())
                }
            }
        } else if let columns = columns {
            VStack(alignment: self.verticalAlignment) {
                ForEach(0 ..< Int(round(Double(array.count / columns))), id: \.self) { row in
                    HStack(alignment: self.horizontalAlignment) {
                        ForEach(0 ..< columns, id: \.self) { column in
                            content(self.array[row*column])
                                .id(self.array[row*column].id)
                                .onAppear { print(self.array[row*column].id) }
                        }
                        .id(UUID())
                    }
                }
                .id(UUID())
            }
        }
    }
}

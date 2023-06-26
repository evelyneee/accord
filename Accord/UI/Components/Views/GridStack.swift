//
//  GridStack.swift
//  Accord
//
//  Created by evelyn on 2022-05-30.
//

import SwiftUI

struct GridStack<T: RandomAccessCollection & Equatable, Content: View>: View, Equatable where T.Index == Int, T.Element: Identifiable & Hashable {
    
    static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.array == rhs.array
    }
    
    let rows: Int?
    let columns: Int?
    let verticalAlignment: SwiftUI.HorizontalAlignment
    let horizontalAlignment: SwiftUI.VerticalAlignment
    var array: T
    let content: (T.Element) -> Content

    init(_ array: T, rowAlignment: SwiftUI.HorizontalAlignment = .center, columnAlignment: SwiftUI.VerticalAlignment = .center, rows: Int? = nil, columns: Int? = nil, @ViewBuilder content: @escaping (T.Element) -> Content) {
        self.array = array
        verticalAlignment = rowAlignment
        horizontalAlignment = columnAlignment
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
                            content(self.array[row * column])
                                .id(self.array[row * column].id)
                        }
                    }
                    .fixedSize()
                }
            }
            .fixedSize()
        } else if let columns = columns {
            let chunked = self.array.arrayLiteral.chunked(by: columns)
            VStack(alignment: self.verticalAlignment) {
                ForEach(0 ..< (chunked.count), id: \.self) { row in
                    HStack(alignment: self.horizontalAlignment) {
                        ForEach(chunked[row], id: \.id) { item in
                            content(item)
                                .id(item.id)
                        }
                    }
                    .fixedSize()
                }
            }
            .fixedSize()
        }
        
    }
}

extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

extension Binding: Equatable where Value: Equatable {
    public static func == (lhs: Binding<Value>, rhs: Binding<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Binding: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.wrappedValue)
    }
}

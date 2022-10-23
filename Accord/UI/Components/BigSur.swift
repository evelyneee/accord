//
//  BigSur.swift
//  Accord
//
//  Created by evelyn on 2022-10-23.
//

import SwiftUI

@available(macOS 11.0, *) @available(macOS, deprecated: 12.0)
enum TextSelection {
    case enabled
    case disabled
}

@available(macOS 11.0, *) @available(macOS, deprecated: 12.0)
enum DynamicTypeSizes {
    case xxxLarge
}

@available(macOS 11.0, *) @available(macOS, deprecated: 12.0)
enum SubmitTypes {
    case search
    case text
}

@available(macOS 11.0, *) @available(macOS, deprecated: 12.0)
enum SymbolRenderingMode2 {
    case palette
}

@available(macOS 11.0, *) @available(macOS, deprecated: 12.0)
struct Material: View {
    
    static var thick = Self.init()
    
    var body: some View {
        Color.secondary
    }
}

@available(macOS 11.0, *) @available(macOS, deprecated: 12.0)
extension View {
    
    @ViewBuilder @_disfavoredOverload
    func textSelection(_ selection: TextSelection) -> some View {
        if #available(macOS 12.0, *) {
            if selection == .enabled {
                self.textSelection(EnabledTextSelectability.enabled)
            } else if selection == .disabled {
                self.textSelection(DisabledTextSelectability.disabled)
            }
        } else {
            self
        }
    }
    
    @ViewBuilder @_disfavoredOverload
    func dynamicTypeSize(_ size: DynamicTypeSizes) -> some View {
        if #available(macOS 12.0, *) {
            self.dynamicTypeSize(DynamicTypeSize.xxxLarge)
        } else {
            self
        }
    }
    
    @ViewBuilder @_disfavoredOverload
    func onSubmit(
        of submitType: SubmitTypes = .text,
        _ action: @escaping (() -> Void)
    ) -> some View {
        if #available(macOS 12.0, *) {
            if submitType == .search {
                self.onSubmit(of: SubmitTriggers.search, action)
            } else {
                self.onSubmit(of: SubmitTriggers.text, action)
            }
        } else {
            HStack {
                self
                Button(submitType == .search ? "Search" : "Send") {
                    action()
                }
            }
        }
    }
    
    @_disfavoredOverload
    func id(_ id: any Hashable) -> some View {
        self
    }
    
    @_disfavoredOverload @ViewBuilder
    func symbolRenderingMode(_ mode: SymbolRenderingMode2?) -> some View {
        if #available(macOS 12.0, *), mode == .palette {
            self.symbolRenderingMode(SymbolRenderingMode.palette)
        } else {
            self
        }
    }
    
    @_disfavoredOverload @ViewBuilder
    func foregroundStyle<S>(_ style: S) -> some View where S : ShapeStyle {
        if #available(macOS 12.0, *) {
            self.foregroundStyle(style)
        } else {
            self
        }
    }
    
    @_disfavoredOverload @ViewBuilder
    func foregroundStyle<S1, S2>(
        _ primary: S1,
        _ secondary: S2
    ) -> some View where S1 : ShapeStyle, S2 : ShapeStyle {
        if #available(macOS 12.0, *) {
            self.foregroundStyle(primary, secondary)
        } else {
            self
        }
    }
}

@available(macOS 11.0, *) @available(macOS, deprecated: 12.0)
extension Binding: Identifiable where Value: Identifiable {
    public var id: Value.ID {
        self.wrappedValue.id
    }
}

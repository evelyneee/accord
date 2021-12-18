//
//  TableView.swift
//  Accord
//
//  Created by evelyn on 2021-12-12.
//

import Foundation
import SwiftUI

extension NSResponder {
    func next<T: NSResponder>(_ type: T.Type) -> T? {
        return nextResponder as? T ?? nextResponder?.next(T.self)
    }
}

struct TestView: View {
    var body: some View {
        TableView.init(["cock"], content: { value in
            Text(value)
        })
    }
}

struct TableView<T: Collection, Content: View>: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    
    var views: [NSView] = []
    
    public init(_ array: T, @ViewBuilder content: @escaping (T.Element) -> Content) {
        let array = array.reversed()
        views.append(NSHostingView.init(rootView: Text("This is the beginnning of this channel").font(.title).fontWeight(.bold)))
        for val in array {
            let view = content(val)
            let nsView = NSHostingView(rootView: view)
            views.append(nsView)
        }
        views.append(NSHostingView(rootView: Spacer().frame(height: 90)))
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let tableContainer = NSScrollView(frame: .zero)
    
        let tableView = NSTableView(frame: .zero)
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "column"))
        tableView.headerView = nil
        column.width = 1
        tableView.addTableColumn(column)
        tableView.usesAutomaticRowHeights = true
        tableContainer.documentView = tableView
        tableContainer.hasVerticalScroller = true
        if !views.isEmpty {
            tableView.scrollRowToVisible(views.count)
        }
        return tableContainer
    }
  
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        
        guard let tableView = nsView.documentView as? NSTableView else { return }
        context.coordinator.views = views
        tableView.reloadData()
    }
  
    func makeCoordinator() -> Coordinator {
        return Coordinator(views: views)
    }
}

extension TableView {
    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var views: [NSView]
        init(views: [NSView]) {
            self.views = views
        }
        func numberOfRows(in tableView: NSTableView) -> Int {
            return views.count
        }
                
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            return views[row]
        }
    }
}

struct SampleViewController: NSViewRepresentable {
    
    var tableView:NSTableView = {
        let table = NSTableView(frame: NSRect.init(x: 0, y: 0, width: 400, height: 400))
        table.rowSizeStyle = .large
        table.backgroundColor = .yellow
        return table
    }()
    
    func makeNSView(context: Context) -> NSTableView {
        
        return tableView
    }
    
    func updateNSView(_ nsView: NSTableView, context: Context) {
        //tbd
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var parent: SampleViewController
        
        init(_ tvController: SampleViewController) {
            self.parent = tvController
        }
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            return 10
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            return NSTextField.init(labelWithString: "cock")
        }
        
        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            return CGFloat(90)
        }
        
        func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
            return false
        }

    }

    
}


struct SampleView: View {
    var body: some View {
        SampleViewController()
    }
}

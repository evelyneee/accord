//
//  FileAttachmentView.swift
//  Accord
//
//  Created by evelyn on 2022-05-23.
//

import QuickLook
import SwiftUI
import UniformTypeIdentifiers

struct FileAttachmentView: View {
    var file: AttachedFiles
    @State var quickLookURL: URL?

    var formattedSize: String {
        let megabytes = file.size >= 1_048_576
        if megabytes {
            return String(Double(file.size / 1_048_576)) + " mb"
        } else {
            return String(Double(file.size / 1024)) + " kb"
        }
    }

    var body: some View {
        HStack {
            Image(nsImage: NSWorkspace.shared.icon(for: UTType(mimeType: file.content_type ?? "application/text") ?? .text))
            VStack(alignment: .leading) {
                Text(file.filename)
                    .fontWeight(.medium)
                    .font(.system(size: 14))
                    .lineLimit(0)
                Text(formattedSize)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(0)
            }
            Spacer()
            Button(action: {
                if let quickLookURL = quickLookURL {
                    try? FileManager.default.removeItem(at: quickLookURL)
                    self.quickLookURL = nil
                } else {
                    Request.fetch(url: URL(string: file.url), headers: .init(type: .GET)) {
                        switch $0 {
                        case let .success(data):
                            print(data)
                            let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                                .appendingPathComponent(file.filename)
                            try? data.write(to: path)
                            self.quickLookURL = path
                        case let .failure(error):
                            print(error)
                        }
                    }
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 5)

            Button(action: {
                guard let url = URL(string: self.file.url) else { return }
                NSWorkspace.shared.open(url)
            }, label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17))
                    .contentShape(Rectangle())
            })
            .buttonStyle(.borderless)
            .padding(.trailing, 5)
        }
        .padding(5)
        .frame(width: 250)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(5)
        .quickLookPreview(self.$quickLookURL)
    }
}

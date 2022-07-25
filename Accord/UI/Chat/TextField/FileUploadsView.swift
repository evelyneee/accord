//
//  FileUploadsView.swift
//  Accord
//
//  Created by evelyn on 2022-07-10.
//

import SwiftUI

struct FileUploadsView: View {
    @Binding var fileUploads: [(Data?, URL?)]
    var body: some View {
        HStack {
            ForEach(Array(zip(self.fileUploads.indices, self.fileUploads)), id: \.1.1) { offset, item in
                let data = item.0
                let url = item.1
                VStack(alignment: .leading, content: {
                    ZStack(alignment: .topTrailing) {
                        if let data = data, let nsImage = NSImage(data: data) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .frame(height: 130)
                            
                        } else {
                            ZStack(alignment: .center) {
                                Image(systemName: "doc")
                                    .font(.largeTitle)
                                    .foregroundColor(Color.primary.opacity(0.4))
                            }
                            .frame(width: 130, height: 130)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(5)
                        }
                        
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.black, Color.white.opacity(0.5))
                            .frame(width: 22, height: 22)
                            .onTapGesture {
                                self.fileUploads.remove(at: offset)
                            }
                            .padding(4)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(url?.lastPathComponent ?? "")
                })
            }
        }
    }
}

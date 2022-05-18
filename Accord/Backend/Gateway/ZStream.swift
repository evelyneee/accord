//
//  ZStream.swift
//  Accord
//
//  Created by evelyn on 2022-04-13.
//

import Foundation
import Compression

final class ZStream {
    
    let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
    var stream: compression_stream
    var status: compression_status
    let decompressionQueue = DispatchQueue(label: "red.evelyn.accord.DecompressionQueue")
    private var lock: Bool = false
    
    init () {
        self.stream = streamPtr.pointee
        status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
    }
    
    func decompress(data: Data, large: Bool = false) throws -> Data {
        guard lock == false else {
            self.decompressionQueue.async {
                _ = try? self.decompress(data: data)
            }
            throw "Already decompressing"
        }
        lock = true
        defer { lock = false }
        // header check
        let hasHeader = data.prefix(2) == Data([0x78, 0x9C])
        let data = hasHeader ? data.dropFirst(2) : data
        let outputData = data.withUnsafeBytes { buf -> Data? in
            let bytes = buf.bindMemory(to: UInt8.self).baseAddress!
            // setup the stream's source
            stream.src_ptr = bytes
            stream.src_size = data.count
            
            // setup the stream's output buffer
            // we use a temporary buffer to store the data as it's compressed
            let dstBufferSize : size_t = large ? 32768 : 4096
            let dstBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstBufferSize)
            stream.dst_ptr = dstBufferPtr
            stream.dst_size = dstBufferSize
            // and we store the output in a mutable data object
            var outputData = Data()
            
            // loop labels :D
            mainLoop: repeat {
                status = compression_stream_process(&stream, 0)

                switch status {
                case COMPRESSION_STATUS_OK:
                    // Going to call _process at least once more, so prepare for that
                    if stream.dst_size == 0 {
                        // Output buffer full...
                        
                        // Write out to outputData
                        outputData.append(dstBufferPtr, count: dstBufferSize)
                        
                        // Re-use dstBuffer
                        stream.dst_ptr = dstBufferPtr
                        stream.dst_size = dstBufferSize
                    } else {
                        if stream.dst_ptr > dstBufferPtr {
                            outputData.append(dstBufferPtr, count: stream.dst_ptr - dstBufferPtr)
                            // terminate process
                            break mainLoop
                        }
                    }
                    
                case COMPRESSION_STATUS_END:
                    // We are done, just write out the output buffer if there's anything in it
                    print("doneeeee")
                    if stream.dst_ptr > dstBufferPtr {
                        outputData.append(dstBufferPtr, count: stream.dst_ptr - dstBufferPtr)
                        break mainLoop
                    }
                default:
                    break mainLoop
                }
                
            } while status == COMPRESSION_STATUS_OK
            return outputData
        }
        guard let outputData = outputData else { throw ZlibErrors.noData }
        lock = false
        return outputData
    }
    
    enum ZlibErrors: Error {
        case noData
        case threadError
    }
    
    deinit {
        compression_stream_destroy(&stream)
    }
}

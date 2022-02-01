//
//  IPC.swift
//  Accord
//
//  Created by evelyn on 2022-01-15.
//

import Darwin
import Foundation

class IPC {
    let servicePort = "6463"

    func start() {
        let socket = socket(AF_UNIX, SOCK_STREAM, 0)
        let path = NSTemporaryDirectory().appending("discord-ipc-0")
        let url = URL(fileURLWithPath: path)
        try! "".write(to: url, atomically: true, encoding: .utf8)
        print(path, socket, url.absoluteString)
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let lengthOfPath = path.utf8.count
        addr.sun_len = UInt8(MemoryLayout<UInt8>.size + MemoryLayout<sa_family_t>.size + path.utf8.count + 1)

        guard lengthOfPath < MemoryLayout.size(ofValue: addr.sun_path) else {
            return
        }

        _ = withUnsafeMutablePointer(to: &addr.sun_path.0) { ptr in
            path.withCString {
                strncpy(ptr, $0, lengthOfPath)
            }
        }
        var address: UnsafePointer<sockaddr>?
        withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                address = $0
            }
        }
        print(addr, socket, "uwu")
        unlink(path.cString)
        let socketFD = bind(socket, address!, UInt32(MemoryLayout<sockaddr_un>.stride))
        print(socketFD, errno)
        func listener() {
            let listenResult = listen(socketFD, 10)
            if listenResult == -1 {
                return
            }
            let MTU = 65536
            var addr = sockaddr()
            var addr_len: socklen_t = 0

            print("About to accept")
            let clientFD = accept(socketFD, &addr, &addr_len)

            if clientFD != -1 {
                print("Accepted new client with file descriptor: \(clientFD)")
            } else {}
            var buffer = UnsafeMutableRawPointer.allocate(byteCount: MTU, alignment: MemoryLayout<CChar>.size)
            func receive() {
                let readResult = read(clientFD, &buffer, MTU)

                if readResult == 0 {
                } else if readResult == -1 {
                    print("Error reading form client\(clientFD) - \(errno)")
                    return
                } else {
                    withUnsafeMutablePointer(to: &buffer) {
                        $0.withMemoryRebound(to: UInt8.self, capacity: readResult + 1) {
                            $0.advanced(by: readResult).assign(repeating: 0, count: 1)
                        }
                    }
                    let strResult = withUnsafePointer(to: &buffer) {
                        $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: readResult)) {
                            String(cString: $0)
                        }
                    }
                    print("Received form client(\(clientFD)): \(strResult)")
                    write(clientFD, &buffer, readResult)
                }
                receive()
            }
            receive()
        }
        listener()
    }
}

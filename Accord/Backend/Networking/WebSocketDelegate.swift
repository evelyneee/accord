//
//  WebSocketDelegate.swift
//  Accord
//
//  Created by evelyn on 2021-12-17.
//

import Foundation

final class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    static var shared = WebSocketDelegate()
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        releaseModePrint("Web Socket did connect")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        releaseModePrint("Web Socket did disconnect")
        let reason = String(decoding: reason ?? Data(), as: UTF8.self)
        MessageController.shared.sendWSError(msg: reason)
        print("Error from Discord: \(reason)")
        if reason.contains("auth") {
            _ = KeychainManager.save(key: "me.evelyn.accord.token", data: Data())
        }
        // MARK: WebSocket close codes.
        switch closeCode {
        case .invalid:
            releaseModePrint("Socket closed because payload was invalid")
        case .normalClosure:
            releaseModePrint("Socket closed because connection was closed")
            releaseModePrint(reason)
        case .goingAway:
            releaseModePrint("Socket closed because connection was closed")
            releaseModePrint(reason)
        case .protocolError:
            releaseModePrint(" Socket closed because there was a protocol error")
        case .unsupportedData:
            releaseModePrint("Socket closed input/output data was unsupported")
        case .noStatusReceived:
            releaseModePrint("Socket closed no status was received")
        case .abnormalClosure:
            releaseModePrint("Socket closed, there was an abnormal closure")
        case .invalidFramePayloadData:
            releaseModePrint("Socket closed the frame data was invalid")
        case .policyViolation:
            releaseModePrint("Socket closed: Policy violation")
        case .messageTooBig:
            releaseModePrint("Socket closed because the message was too big")
        case .mandatoryExtensionMissing:
            releaseModePrint("Socket closed because an extension was missing")
        case .internalServerError:
            releaseModePrint("Socket closed because there was an internal server error")
        case .tlsHandshakeFailure:
            releaseModePrint("Socket closed because the tls handshake failed")
        @unknown default:
            releaseModePrint("Socket closed for unknown reason")
        }
    }
}


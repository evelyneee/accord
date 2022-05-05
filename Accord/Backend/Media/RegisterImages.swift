//
//  RegisterImages.swift
//  Accord
//
//  Created by evelyn on 2022-01-31.
//

import Combine
import Foundation

class ExternalImages {
    class RPCResponse: Decodable {
        var url: String
        var external_asset_path: String
    }

    class func proxiedURL(appID: String, url: String) -> AnyPublisher<[RPCResponse], Error> {
        RequestPublisher.fetch([RPCResponse].self, url: URL(string: "\(rootURL)/applications/\(appID)/external-assets"), headers: Headers(
            userAgent: discordUserAgent,
            token: AccordCoreVars.token,
            bodyObject: ["urls": [url]],
            type: .POST,
            discordHeaders: true,
            json: true
        ))
    }
}

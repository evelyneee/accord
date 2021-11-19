//
//  MessageGrouping.swift
//  MessageGrouping
//
//  Created by evelyn on 2021-09-08.
//

import Foundation

extension ChannelView {
    func fastIndexMessage(_ message: String, array: [Message]) -> Int? {
        let messageDict = array.enumerated().compactMap { (index, element) in
            return [element.id:index]
        }.reduce(into: [:]) { (result, next) in
            result.merge(next) { (_, rhs) in rhs }
        }
        return messageDict[message]
    }
}

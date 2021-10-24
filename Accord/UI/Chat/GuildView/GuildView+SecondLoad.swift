//
//  GuildView+SecondLoad.swift
//  GuildView+SecondLoad
//
//  Created by evelyn on 2021-08-23.
//

import Foundation

extension GuildView {
    // MARK: - Second stage of channel loading
    func performSecondStageLoad() {
        if guildID != "@me" {
            var allUserIDs = Array(NSOrderedSet(array: viewModel.messages.map { $0.author?.id ?? "" })) as! Array<String>
            getCachedMemberChunk()
            for (index, item) in allUserIDs.enumerated() {
                if Array(wss.cachedMemberRequest.keys).contains("\(guildID)$\(item)") {
                    if Array<Int>(allUserIDs.indices).contains(index) {
                        allUserIDs.remove(at: index)
                    }
                }
            }
            if !(allUserIDs.isEmpty) {
                wss.getMembers(ids: allUserIDs, guild: guildID)
            }
        }
    }
}

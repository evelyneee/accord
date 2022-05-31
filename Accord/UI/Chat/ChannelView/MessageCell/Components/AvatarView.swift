//
//  AvatarView.swift
//  Accord
//
//  Created by evelyn on 2022-05-30.
//

import SwiftUI

struct AvatarView: View {
    
    var author: User
    var guildID: String
    var avatar: String?
    
    @ViewBuilder
    var body: some View {
        if (self.avatar?.prefix(2) ?? author.avatar?.prefix(2)) == "a_" {
            GifView({ () -> String in
                if let avatar = self.avatar {
                    return cdnURL + "/guilds/\(guildID)/users/\(author.id)/avatars/\(avatar).gif?size=48"
                } else {
                    return cdnURL + "/avatars/\(author.id)/\(author.avatar!).gif?size=48"
                }
            }())
        } else {
            Attachment ({ () -> String in
                if let avatar = self.avatar {
                    return cdnURL + "/guilds/\(guildID)/users/\(author.id)/avatars/\(avatar).png?size=48"
                } else if let avatar = author.avatar {
                    return cdnURL + "/avatars/\(author.id)/\(avatar).png?size=48"
                } else {
                    let index = String((Int(author.discriminator) ?? 0) % 5)
                    return cdnURL + "/embed/avatars/\(index).png"
                }
            }())
            .equatable()
        }
    }
}

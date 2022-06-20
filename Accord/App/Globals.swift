//
//  Storage.swift
//  Accord
//
//  Created by evelyn on 2022-06-18.
//

import Foundation
import Combine

enum Storage {
    
    public static var usernames = [String: String]()
    public static var emotes = [String: [DiscordEmote]]()
    
    // these should be merged ideally
    public static var roleColors = [String: (Int, Int)]()
    public static var roleNames = [String: String]()
    
    public static var folders = [GuildFolder]()
    public static var privateChannels = [Channel]()
    public static var mergedMembers = [String: Guild.MergedMember]()
}

final class AppGlobals: ObservableObject {
        
    public var usernames = [String: String]()
    public var emotes = [String: [DiscordEmote]]()
    
    // these should be merged ideally
    public var roleColors = [String: (Int, Int)]()
    public var roleNames = [String: String]()
    
    public var folders = [GuildFolder]()
    public var privateChannels = [Channel]()
    public var mergedMembers = [String: Guild.MergedMember]()
}

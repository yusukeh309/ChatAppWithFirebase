//
//  ChatRoom.swift
//  ChatAppWithFirebase
//
//  Created by Uske on 2020/03/29.
//  Copyright © 2020 Uske. All rights reserved.
//

import Foundation
import Firebase

class ChatRoom {
    
    let latestMessageId: String
    let memebers: [String]
    let createdAt: Timestamp
    
    var partnerUser: User?
    
    init(dic: [String: Any]) {
        self.latestMessageId = dic["latestMessageId"] as? String ?? ""
        self.memebers = dic["memebers"] as? [String] ?? [String]()
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
    }
    
}

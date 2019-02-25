//
//  Message.swift
//  GameOfThronesChat
//
//  Created by MikeLi on 2019-02-22.
//  Copyright © 2019 MikeLi. All rights reserved.
//

import UIKit
import Firebase

class Message {
    var fromId: String?
    var toId: String?
    var text: String?
    var timestamp: String?
    
    var imageUrl: String?
    
    init(fromId: String, toIDd: String, text: String?, timeInterval: String, imageUrl: String?) {
        self.fromId = fromId
        self.toId = toIDd
        self.text = text
        self.timestamp = timeInterval
        self.imageUrl = imageUrl
    }
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser!.uid ? toId : fromId
    }
}

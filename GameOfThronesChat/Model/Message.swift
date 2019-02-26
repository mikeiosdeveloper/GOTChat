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
    var imageWidth: CGFloat?
    var imageHeight: CGFloat?
    
    init(dictionary: [String: Any]) {
        self.fromId = dictionary["fromId"] as? String
        self.toId = dictionary["toId"] as? String
        self.text = dictionary["text"] as? String
        self.timestamp = dictionary["timestamp"] as? String
        self.imageUrl = dictionary["imageUrl"] as? String
        self.imageWidth = dictionary["imageWidth"] as? CGFloat
        self.imageHeight = dictionary["imageHeight"] as? CGFloat
    }
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser!.uid ? toId : fromId
    }
}

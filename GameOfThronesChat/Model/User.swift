//
//  User.swift
//  GameOfThronesChat
//
//  Created by MikeLi on 2019-02-20.
//  Copyright © 2019 MikeLi. All rights reserved.
//

import UIKit

class User: NSObject {
    var id: String?
    var name: String
    var email: String
    var profileImageUrl: String?
    
    init(id: String?, name: String, email: String, profileImageUrl: String?) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageUrl = profileImageUrl
    }
}

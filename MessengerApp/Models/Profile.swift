//
//  Profile.swift
//  MessengerApp
//
//  Created by Ayman  on 6/27/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import Foundation

struct Profile {
    let type: ProfileType
    let title: String
    let hander: (() -> Void)?
}

enum ProfileType {
    case info, logout
}

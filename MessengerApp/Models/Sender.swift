//
//  Sender.swift
//  MessengerApp
//
//  Created by Ayman  on 6/22/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import Foundation
import MessageKit

struct Sender:SenderType {
   public var photoURL:String
   public var senderId: String
   public var displayName: String
}

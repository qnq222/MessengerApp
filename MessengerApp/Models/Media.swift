//
//  Media.swift
//  MessengerApp
//
//  Created by Ayman  on 6/25/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import Foundation
import MessageKit

struct Media: MediaItem {
    var url: URL? 
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

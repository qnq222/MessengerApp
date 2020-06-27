//
//  Location.swift
//  MessengerApp
//
//  Created by Ayman  on 6/27/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

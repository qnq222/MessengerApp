//
//  Extensions.swift
//  MessengerApp
//
//  Created by Ayman  on 6/16/20.
//  Copyright © 2020 Ayman . All rights reserved.
//
import Foundation
import UIKit

extension UIView {
 
    public var width:CGFloat {
        return frame.size.width
    }
    
    public var height:CGFloat {
        return frame.size.height
    }
    
    public var top:CGFloat {
        return frame.origin.y
    }
    
    public var bottom:CGFloat {
        return frame.size.height + frame.origin.y
    }
    
    public var left:CGFloat {
        return frame.origin.x
    }
    
    public var right:CGFloat {
        return frame.size.width + frame.origin.x
    }
}

extension Notification.Name {
    /// a notification when the user logs in 
    static let didLoginNotification = Notification.Name("didLoginNotification ")
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}

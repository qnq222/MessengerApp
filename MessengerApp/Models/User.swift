//
//  User.swift
//  MessengerApp
//
//  Created by Ayman  on 6/22/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import Foundation

struct User {
    let firstName:String
    let lastName:String
    let emailAddress:String
    
    
    // compute proparty to make the email address safe i.e the firebase accept it :
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        /*
         user_email_profile_picture.png
         a-a-com_profile_picture.png
         */
        return "\(safeEmail)_profile_picture.png"
    }
}

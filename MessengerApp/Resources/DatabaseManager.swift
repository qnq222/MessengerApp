//
//  DatabaseManager.swift
//  MessengerApp
//
//  Created by Ayman  on 6/17/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import Foundation
import FirebaseDatabase


final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    
}
// MARK: - Account Management:

extension DatabaseManager {
    
    /// validate the user if existing or not true if the user does not exist and false if exist
    public func userExists(with email: String , completion: @escaping ((Bool) -> Void)){
        database.child(email).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil  else {
              completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// insert new user to the database
    public func insertUser(with user: User) {
        database.child(user.emailAddress).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
}

struct User {
    let firstName:String
    let lastName:String
    let emailAddress:String
    //let profilePhotoUrl: String
}


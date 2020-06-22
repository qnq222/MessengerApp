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
    
    static func safeEmail(emailAddress: String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}
// MARK: - Account Management:

extension DatabaseManager {
    
    /// validate the user if existing or not true if the user does not exist and false if exist
    public func userExists(with email: String , completion: @escaping ((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil  else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// insert new user to the database
    public func insertUser(with user: User , completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
            ] , withCompletionBlock: {error , _ in
                guard error == nil else {
                    print("failed to write data to database")
                    completion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                    if var usersCollection = snapshot.value as? [[String:String]] {
                        // append to user dictionary:
                        let newElement = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection , withCompletionBlock: {error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                        
                    }else {
                        // create that array:
                        let newCollection: [[String:String]] = [
                            [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                            ]
                        ]
                        
                        self.database.child("users").setValue(newCollection , withCompletionBlock: {error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                })
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]] , Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetchData))
                return
            }
            completion(.success(value ))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetchData
    }
}

/*
 the database schema for the users for the search functionality
 users => [
 [
 "name":
 "safe_email":
 ],
 [
 "name":
 "safe_email":
 ]
 ]
 */

// MARK: - Sending message / conversaations:
extension DatabaseManager {
    
    /*
     the database schema for the conversation / message
     "12desa25rwqerq" {
     "messages": [
             {
             "id": String,
             "type": text or photo or video ,
             "content": the content will be based on the message type,
             "date": Date(),
             "sender_email": String,
             "is_message_read": Bool,
             }
        ]
     }
     
     
     conversations => [
         [
             uniqe id "conversation_id": "12desa25rwqerq"
             "other_user_email":
             "latest_message" => {
             "date" = Date()
             "latest_message" = "message"
             "is_message_read" = true / false
             }
         ]
     ]
     */
    
    /// Creates a new conversation with the taget user email and first message snet.
    public func createNewConversation(with othreUserEmail: String,
                                      firstMessage: Message , completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let reference = database.child(safeEmail)
        reference.observeSingleEvent(of: .value, with: {snapshot in
            guard var userNode = snapshot.value as? [String: Any] else{
                completion(false)
                print("user not found!!!")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": othreUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_message_read": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // the conversation exist for the current user
                // append the conversation
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                reference.setValue(userNode , withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationId,
                                                    firstMessage: firstMessage,
                                                    completion: completion)
                })
            } else {
                // conversation array does not exist we must create it:
                userNode["conversations"] = [
                    newConversationData
                ]
                
                reference.setValue(userNode , withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationId,
                                                    firstMessage: firstMessage,
                                                    completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        /*
        {
         "id": String,
         "type": text or photo or video ,
         "content": the content will be based on the message type,
         "date": Date(),
         "sender_email": String,
         "is_message_read": Bool,
        }
         */
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeCurrentUserEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": safeCurrentUserEmail ,
            "is_message_read": false,
        ]
        
        let value: [String: Any] = [
            "message": [
                collectionMessage
            ]
        ]
        
        print("adding a conversation: \(conversationID)")
        
        database.child(conversationID).setValue(value, withCompletionBlock: {error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and returns all conversations for the user with the passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String , Error>) -> Void) {
        
    }
    
    /// fetches all the messages for conversation id passed in
    public func getAllMessageForConversation(with id: String, completion: @escaping (Result<String,Error>) -> Void){
        
    }
    
    // sends a message with a target converation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void){
        
    }
}


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


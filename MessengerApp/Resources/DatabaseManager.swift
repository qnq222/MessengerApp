//
//  DatabaseManager.swift
//  MessengerApp
//
//  Created by Ayman  on 6/17/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

/// manager oject to read and write data to real time database
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

extension DatabaseManager {
    
    /// get the data for a specific path passed in
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void){
        database.child("\(path)").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetchData))
                return
            }
            completion(.success(value))
        })
    }
}

// MARK: - Account Management:

extension DatabaseManager {
    
    /// validate the user if existing or not true if the user does not exist and false if exist
    /// Parameters:
    /// - `email`: target email to be checked.
    /// - `completion`: asnyc closure to return with result
    public func userExists(with email: String , completion: @escaping ((Bool) -> Void)){
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [String: Any] != nil  else {
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
            ] , withCompletionBlock: { [weak self] error , _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                guard error == nil else {
                    print("failed to write data to database")
                    completion(false)
                    return
                }
                
                strongSelf.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                    if var usersCollection = snapshot.value as? [[String:String]] {
                        // append to user dictionary:
                        let newElement = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        strongSelf.database.child("users").setValue(usersCollection , withCompletionBlock: {error, _ in
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
                        
                        strongSelf.database.child("users").setValue(newCollection , withCompletionBlock: {error, _ in
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
    public func createNewConversation(with otherUserEmail: String,
                                      name:String,
                                      firstMessage: Message , completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let reference = database.child("\(safeEmail)")
        reference.observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_message_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail ,
                "name": currentUserName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_message_read": false
                ]
            ]
            
            // update recipient user conversation entry:
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapchot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            
            // update current user conversation entry:
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
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
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
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(name: String,
                                            conversationID: String,
                                            firstMessage: Message, completion: @escaping (Bool) -> Void){
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
            "sender_email": safeCurrentUserEmail,
            "is_message_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
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
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetchData))
                return
            }
            let conversations: [Conversation] = value.compactMap({dictionary in
                guard let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let sentDate = latestMessage["date"] as? String,
                    let isMessageRead = latestMessage["is_message_read"] as? Bool,
                    let message = latestMessage["message"] as? String else {
                        return nil
                }
                
                let latestMesssageObject = LatestMessage(date: sentDate,
                                                         message: message,
                                                         isMessageRead: isMessageRead)
                
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMesssageObject)
            })
            completion(.success(conversations))
        })
    }
    
    /// fetches all the messages for conversation id passed in
    public func getAllMessageForConversation(with id: String, completion: @escaping (Result<[Message],Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetchData))
                return
            }
            let messages: [Message] = value.compactMap({dictionary in
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_message_read"] as? Bool,
                    let messageId = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let messageType = dictionary["type"] as? String,
                    let date = dictionary["date"] as? String,
                    let dateString = ChatViewController.dateFormatter.date(from: date) else {
                        return nil
                }
                
                var messageKind: MessageKind?
                
                if messageType == "photo" {
                    // the message type is a photo:
                    
                    guard let imageUrl = URL(string: content),
                        let placeHolder = UIImage(systemName: "plus") else {
                            return nil
                    }
                    
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    
                    messageKind = .photo(media)
                } else if messageType == "video" {
                    // the message type is a video:
                    guard let vidoeUrl = URL(string: content),
                        let placeHolder = UIImage(named: "video_placeHolder") else {
                            return nil
                    }
                    
                    let media = Media(url: vidoeUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    
                    messageKind = .video(media)
                } else if messageType == "location" {
                  // location message:
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                    let latitude = Double(locationComponents[1]) else {
                        return nil
                    }
                    print("rendering location: longitude = \(longitude) , latitude = \(latitude)")
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                            size: CGSize(width: 300, height: 300))
                    
                    messageKind = .location(location)
                    
                } else {
                    // its a text message:
                    messageKind = .text(content)
                }
                
                guard let finalKind = messageKind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageId,
                               sentDate: dateString,
                               kind: finalKind)
            })
            completion(.success(messages))
        })
    }
    
    // sends a message with a target converation and message
    public func sendMessage(to conversationId: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        // add a new message to messages
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessage = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage .kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
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
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": safeCurrentUserEmail,
                "is_message_read": false,
                "name": name
            ]
            
    //MARK:- append the message to the meessages array
            currentMessage.append(newMessageEntry)
            
            strongSelf.database.child("\(conversationId)/messages").setValue(currentMessage, withCompletionBlock: {error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                // update sender latest message
                strongSelf.database.child("\(currentSafeEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                    var databaseEntryConversation = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_message_read": false,
                        "message": message
                    ]
                    
                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
                        var targetConveration: [String: Any]?
                        var position = 0
                        
                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String,
                                currentId == conversationId {
                                targetConveration = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        if var targetConveration = targetConveration {
                            targetConveration["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConveration
                            databaseEntryConversation = currentUserConversations
                        } else {
                            let newConversationData: [String: Any] = [
                                "id": conversationId,
                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversation = currentUserConversations
                        }
                        
                    } else {
                        let newConversationData: [String: Any] = [
                            "id": conversationId,
                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        databaseEntryConversation = [newConversationData]
                    }
                    
                    strongSelf.database.child("\(currentSafeEmail)/conversations").setValue(databaseEntryConversation, withCompletionBlock: {error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
    //MARK:- update recipient latest message:
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_message_read": false,
                                "message": message
                            ]
                            var databaseEntryConversation = [[String: Any]]()
                            
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            
                            if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                var targetConveration: [String: Any]?
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String,
                                        currentId == conversationId {
                                        targetConveration = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                 
                                if var targetConveration = targetConveration {
                                    targetConveration["latest_message"] = updatedValue
                                    otherUserConversations[position] = targetConveration
                                    databaseEntryConversation = otherUserConversations
                                } else {
                                    // failed to find in current collection
                                    let newConversationData: [String: Any] = [
                                        "id": conversationId,
                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentSafeEmail),
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversation = otherUserConversations
                                }
                                
                            } else {
                                // current collection does not exist
                                let newConversationData: [String: Any] = [
                                    "id": conversationId,
                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentSafeEmail),
                                    "name": currentName,
                                    "latest_message": updatedValue
                                ]
                                databaseEntryConversation = [newConversationData]
                            }
                            
                           
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversation, withCompletionBlock: {error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
                
            })
            
        })
    }
    
    /// delete conversation with an id 
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("Starting to delete conversation with id: \(conversationId)")
        
        // get all conversation for current user.
        // delete all conversations in collection for target id.
        // reset those conversaions for the user in database
        let reference = database.child("\(safeEmail)/conversations")
        reference.observe(.value, with: {snapshpt in
            if var conversations = snapshpt.value as? [[String: Any]] {
                var postionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId {
                        print("found conversation id: \(id)")
                        break
                    }
                    postionToRemove += 1
                }
                conversations.remove(at: postionToRemove)
                reference.setValue(conversations, withCompletionBlock: {error, _ in
                    guard error == nil else {
                        completion(false)
                        print("delete conversation failed")
                        return
                    }
                    print("delete conversation successfully")
                    completion(true)
                })
            }
        })
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetchData))
                return
            }
            // iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetchData))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetchData))
            return
            
        })
    }
}

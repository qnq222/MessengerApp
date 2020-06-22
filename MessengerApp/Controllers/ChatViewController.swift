//
//  ChatViewController.swift
//  MessengerApp
//
//  Created by Ayman  on 6/18/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message:MessageType {
   public var sender: SenderType
   public var messageId: String
   public var sentDate: Date
   public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_ext"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender:SenderType {
   public var photoURL:String
   public var senderId: String
   public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale =  .current
        return formatter
    }()
    public let otherUserEmail: String
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        return Sender(photoURL: "",
                      senderId: email,
                      displayName: "Ayman ali")
    }
    
    // so when we create a new object form this view controller we want to initiat the email with it
    // so we can diffetare the users.
    init(with email: String) {
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .link
        
        // a demo message:
        //        messages.append(Message(sender: selfSender,
        //                                messageId: "1",
        //                                sentDate: Date(),
        //                                kind: .text("Hello")))
        
        // messagesCollectionView configuration:
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        //
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        // because we want the keyboard to appear when the view appear not when loaded 
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let messageId = createMessageID() else {
                return
        }
        
        print("sending message: \(text)")
        
        // send the message:
        if isNewConversation {
            // create the conversation in the database:
            let message = Message(sender: selfSender ,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, completion: { [weak self] success in
                guard let strongSelf = self else {
                    return
                }
                if success {
                    print("message sent: \(message) to: \(strongSelf.otherUserEmail)")
                } else {
                    print("Failed to sent message.")
                }
            })
        } else {
            // append to existing data:
        }
    }
    
    private func createMessageID() -> String? {
        //date, othreUserEmail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentUserEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        // Self because dateFormater is static
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentUserEmail)_\(dateString)"
        
        print("created message id: \(newIdentifier)")
        
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate ,MessagesDisplayDelegate {
    // to know who goes to the left or the right, left for the  reciver , right for the sender.
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("self sender is nil, email should be cached.")
        return Sender(photoURL: "", senderId: "12", displayName: "ayman")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        // the MessageKit framework uses the sectios to seperate every single message
        //  because message might have multiple pices like date, time,
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

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
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation
import JGProgressHUD

class ChatViewController: MessagesViewController {
    
    
    private let spinner: JGProgressHUD = {
        let spinner = JGProgressHUD(style: .dark)
        spinner.textLabel.text = "Sending"
        return spinner
    }()
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale =  .current
        return formatter
    }()
    
    public let otherUserEmail: String
    private var conversationId: String?
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }
    
    // so when we create a new object form this view controller we want to initiat the email with it
    // so we can diffetare the users.
    init(with email: String , id: String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        // messagesCollectionView configuration:
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        //
        messageInputBar.delegate = self
        
        //
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // because we want the keyboard to appear when the view appear not when loaded 
        messageInputBar.inputTextView.becomeFirstResponder()
        
        //
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self]  _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo",style: .default, handler: {[weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Vidoe", style: .default, handler: {[weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
        }))
       
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: {[weak self] _ in
            self?.presentLocationPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        }))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker(){
        let locationVC = LocationPickerViewController(coordinates: nil)
        locationVC.title = "Send Location"
        locationVC.navigationItem.largeTitleDisplayMode = .never
        locationVC.completion = {[weak self] selectedCoordinate in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let messageId = strongSelf.createMessageID(),
                let conversationId = strongSelf.conversationId,
                let name = strongSelf.title,
                let selfSender = strongSelf.selfSender else {
                    return
            }
            
            let longitude: Double = selectedCoordinate.longitude
            let latitude: Double = selectedCoordinate.latitude
            
            print("longitude = \(longitude) || latitude = \(latitude) ")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                    size: .zero)
            
            let message = Message(sender: selfSender ,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))

            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {success in
                if success {
                    print("sent location message")
                } else {
                    print("failed to sent message")
                }
            })
            
        }
        navigationController?.pushViewController(locationVC, animated: true)
    }
    
    // a function that handles if the user choose to send images:
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Send a Photo",
                                            message: "you can either take or choose a photo",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera",style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        }))
        
        present(actionSheet, animated: true)
        
    }
    
    // a function that handles if the user choose to send videos:
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Send a Video",
                                            message: "you can either take or choose a video",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera",style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        }))
        
        present(actionSheet, animated: true)
        
    }
    
    private func listenForMessages(id: String , shouldScrollToBottom: Bool){
        DatabaseManager.shared.getAllMessageForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                print("success getting the messages \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
            case .failure(let error):
                print("error getting the messsages form the database: \(error)")
            }
        })
    }
}

// MARK: - View Controller extensions:


// MARK: - InputBarAccessoryViewDelegate:
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let messageId = createMessageID() else {
                return
        }
        
        print("sending message: \(text)")
        
        let message = Message(sender: selfSender ,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        // send the message:
        if isNewConversation {
            // create the conversation in the database:
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    //print("message sent: \(message) to: \(self?.otherUserEmail)")
                    self?.isNewConversation = false
                     let NewConversationId = "conversation_\(message.messageId)"
                    self?.conversationId = NewConversationId
                    self?.listenForMessages(id: NewConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil 
                } else {
                    print("Failed to sent message.")
                }
            })
        } else {
            guard let conversationId = conversationId,
                let name = self.title else {
                    return
            }
            // append to existing data:
            DatabaseManager.shared.sendMessage(to: conversationId,otherUserEmail: otherUserEmail, name: name,newMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent \(message)")
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("Failed to sent message.")
                }
            })
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

// MARK: - MessageKit:
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate ,MessagesDisplayDelegate {
    // to know who goes to the left or the right, left for the  reciver , right for the sender.
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("self sender is nil, email should be cached.")
        //return Sender(photoURL: "", senderId: "12", displayName: "ayman")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        // the MessageKit framework uses the sectios to seperate every single message
        //  because message might have multiple pices like date, time,
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // our message that we sent:
            return .link
        } else {
            return .secondarySystemBackground
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId{
           // show our image
            if let currentUserPhotoURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserPhotoURL, completed: nil)
            } else {
                // image/safeEmail_profile_picture.png
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let imagePath = "images/\(safeEmail)_profile_picture.png"
                // fetch url
                StorageManager.shared.downloadUrl(for: imagePath, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        print("downloaded url: \(url)")
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        } else {
            // show other user image
            if let otherUserPhotoURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserPhotoURL, completed: nil)
            } else {
                // fetch url
                let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let imagePath = "images/\(safeEmail)_profile_picture.png"
                // fetch url
                StorageManager.shared.downloadUrl(for: imagePath, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        print("downloaded url: \(url)")
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("tap message")
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let locationVC = LocationPickerViewController(coordinates: coordinates)
            locationVC.title = "View Location"
            navigationController?.pushViewController(locationVC, animated: true)
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let photoViewVC = PhotoViewerViewController(with: imageUrl )
            navigationController?.pushViewController(photoViewVC, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            let videoViewVC = AVPlayerViewController()
            videoViewVC.player = AVPlayer(url: videoUrl)
            present(videoViewVC, animated: true)
        default:
            break
        }
    }
}

// MARK: - image picker:
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageID(),
            let conversationId = conversationId,
            let name = self.title,
            let selfSender = selfSender else {
                return
        }
        
        spinner.show(in: view)
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            // upload image:
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName , completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // ready to send the message:
                    print("Uploaded message photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeHolder = UIImage(systemName: "plus") else {
                            return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender ,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to sent message")
                        }
                    })
                    self?.spinner.dismiss()
                case .failure(let error):
                    print("failed to upload the message photo: \(error)")
                }
            })
        } else if let videoUrl = info[.mediaURL] as? URL{
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            // upload a video:
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName , completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // ready to send the message:
                    print("Uploaded message video: \(urlString)")
                    guard let url = URL(string: urlString),
                        let placeHolder = UIImage(systemName: "plus") else {
                            return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender ,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {success in
                        if success {
                            print("sent video message")
                        } else {
                            print("failed to sent message")
                        }
                    })
                    self?.spinner.dismiss()
                case .failure(let error):
                    print("failed to upload the message video: \(error)")
                }
            })
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


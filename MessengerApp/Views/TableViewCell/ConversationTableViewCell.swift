//
//  ConversationTableViewCell.swift
//  MessengerApp
//
//  Created by Ayman  on 6/22/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    // MARK: - ui decleration:
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()

    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessaageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    private let messageDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .darkGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // adding the subviews to the main cell view
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessaageLabel)
        contentView.addSubview(messageDateLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // frame each subview:
    override func layoutSubviews() {
        super.layoutSubviews()
       
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 60,
                                     height: 60)
        
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: (contentView.height-20)/2)
        
        userMessaageLabel.frame = CGRect(x: userImageView.right + 10,
                                         y: userNameLabel.bottom + 10,
                                         width: contentView.width - 20 - userImageView.width,
                                         height: (contentView.height-20)/2)
        
        messageDateLabel.frame = CGRect(x: userNameLabel.right - 100,
                                     y: 25,
                                     width: contentView.width,
                                     height: (contentView.height-20)/2)
    }
    
    public func configure(with model: Conversation){
        userNameLabel.text = model.name
        userMessaageLabel.text =  model.latestMessage.message
        let messegeaDate = model.latestMessage.date[0..<6]
        let messageTime = model.latestMessage.date[16..<21]
        messageDateLabel.text = "\(messegeaDate) at \(messageTime)"
        if model.latestMessage.message.contains("message_images") {
            print("image message")
              userMessaageLabel.text = "image message"
        }
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadUrl(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    print("the downloaded url: \(url)")
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("error getting the image url: \(error)")
            }
        })
        
    }
    
}

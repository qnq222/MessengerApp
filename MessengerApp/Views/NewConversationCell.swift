//
//  NewConversationCell.swift
//  MessengerApp
//
//  Created by Ayman  on 6/25/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import SDWebImage

class NewConversationCell: UITableViewCell {
    
    static let identifier = "NewConversationCell "
    
    // MARK: - ui decleration:
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 35 
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // adding the subviews to the main cell view
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // frame each subview:
    override func layoutSubviews() {
        super.layoutSubviews()
       
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 70,
                                     height: 70)
        
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 20,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 50)
    }
    
    public func configure(with model: SearchResult){
        self.userNameLabel.text = model.name
        
        let path = "images/\(model.email)_profile_picture.png"
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

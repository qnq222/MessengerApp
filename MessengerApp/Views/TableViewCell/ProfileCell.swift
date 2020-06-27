//
//  ProfileCell.swift
//  MessengerApp
//
//  Created by Ayman  on 6/27/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit

class ProfileCell: UITableViewCell {
    static let identifier = "ProfileCell"
    public func configure(with viewModel: Profile){
        textLabel?.text = viewModel.title
        switch viewModel.type {
        case .info:
            textLabel?.textAlignment = .left
            textLabel?.font = .systemFont(ofSize: 20)
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}

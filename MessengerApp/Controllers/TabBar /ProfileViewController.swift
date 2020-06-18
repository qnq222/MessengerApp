//
//  ProfileViewController.swift
//  MessengerApp
//
//  Created by Ayman  on 6/16/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileTableView: UITableView!
    
    let tableViewItems = ["Logout"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileTableView.register(UITableViewCell.self, forCellReuseIdentifier: "profileCell")
        
    }
}


extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath)
        cell.textLabel?.text = tableViewItems[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        profileTableView.deselectRow(at: indexPath, animated: true)
        
        
        let actionSheetLogout = UIAlertController(title: "Logout",
                                                  message: "are sure you want to logout?",
                                                  preferredStyle: .actionSheet)
        
        actionSheetLogout.addAction(UIAlertAction(title: "logout",
                                                  style: .destructive,
                                                  handler: { [weak self] _ in
                                                    guard let strongSelf = self else {
                                                        return
                                                    }
                                                    
                                                    // facebook logout:
                                                    FBSDKLoginKit.LoginManager().logOut()
                                                    
                                                    // google logout:
                                                    GIDSignIn.sharedInstance()?.signOut()
                                                    
                                                    // firebase logout:
                                                    do {
                                                        try FirebaseAuth.Auth.auth().signOut()
                                                        let loginVC = LoginViewController()
                                                        let nav = UINavigationController(rootViewController: loginVC)
                                                        nav.modalPresentationStyle = .fullScreen
                                                        strongSelf.present(nav, animated: true)
                                                    }catch{
                                                        print("process fail")
                                                    }
        }))
        
        actionSheetLogout.addAction(UIAlertAction(title: "Cancel",
                                                  style: .cancel, handler: nil))
        
        present(actionSheetLogout, animated: true, completion: nil)
    }
    
}

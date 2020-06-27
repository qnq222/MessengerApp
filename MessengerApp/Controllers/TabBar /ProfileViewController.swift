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
import SDWebImage

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileTableView: UITableView!
    
    var tableViewItems = [Profile]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        
        // tableView configurations:
        profileTableView.dataSource = self
        profileTableView.delegate = self
        profileTableView.tableHeaderView = createTableHeader()
        profileTableView.register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.identifier )
        
        // append date to the tableViewItems:
        tableViewItems.append(Profile(type: .info,
                                      title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "")",
                                      hander: nil))
        tableViewItems.append(Profile(type: .info,
                                      title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "")",
            hander: nil))
        tableViewItems.append(Profile(type: .logout, title: "Logout", hander: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            let actionSheetLogout = UIAlertController(title: "Logout",
                                                      message: "are sure you want to logout?",
                                                      preferredStyle: .actionSheet)
            
            actionSheetLogout.addAction(UIAlertAction(title: "logout",
                                                      style: .destructive,
                                                      handler: { [weak self] _ in
                                                        guard let strongSelf = self else {
                                                            return
                                                        }
                                                        
                                                        UserDefaults.standard.set(nil, forKey: "email")
                                                        UserDefaults.standard.set(nil, forKey: "name")
                                                        
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
            
            strongSelf.present(actionSheetLogout, animated: true, completion: nil)
        }))
        
    }
    
    func createTableHeader() ->UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        // we don't use the shared variable because its a static function.
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let filename = safeEmail + "_profile_picture.png"
        let path = "images/"+filename
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.width,
                                              height: 200))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (view.width-150) / 2 ,
                                                  y: 25,
                                                  width: 150,
                                                  height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth =  3
        imageView.layer.masksToBounds =  true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadUrl(for: path, completion: {result in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get the download url \(error)")
            }
        })
        
        return headerView
    }
}


extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = tableViewItems[indexPath.row]
        let cell = profileTableView.dequeueReusableCell(withIdentifier: ProfileCell.identifier, for: indexPath) as! ProfileCell
        cell.configure(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        profileTableView.deselectRow(at: indexPath, animated: true)
        tableViewItems[indexPath.row].hander?()
    }
    
}

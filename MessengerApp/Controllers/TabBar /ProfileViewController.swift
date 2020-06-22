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
        
        // tableView configurations:
        profileTableView.dataSource = self
        profileTableView.delegate = self
        profileTableView.tableHeaderView = createTableHeader()
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
        
        StorageManager.shared.downloadUrl(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url )
            case .failure(let error):
                print("Failed to get the download url \(error)")
            }
        })
        
        return headerView
    }
    
    func downloadImage(imageView: UIImageView , url:URL){
        URLSession.shared.dataTask(with: url, completionHandler: {data , _ , error in
            guard let data = data , error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
            }).resume()
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

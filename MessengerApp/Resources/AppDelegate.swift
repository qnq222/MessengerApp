//
//  AppDelegate.swift
//  MessengerApp
//
//  Created by Ayman  on 6/16/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate , GIDSignInDelegate{
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        return GIDSignIn.sharedInstance().handle(url)
        
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with google: \(error)")
            }
            return
        }
        
        guard let user = user else {
            return
        }
        
        print("Did sign in with google: \(user)")
        
        guard let email   = user.profile.email,
            let firstname = user.profile.givenName,
            let lastname  = user.profile.familyName else {
                return
        }
        
        // get the user email to save it in the userdefault:
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(firstname) \(lastname)", forKey: "name")
        
        DatabaseManager.shared.userExists(with: email, completion: {exists in
            if !exists {
                // insert the email to database:
                let userChat = User(firstName: firstname,
                                    lastName: lastname,
                                    emailAddress: email)
                DatabaseManager.shared.insertUser(with: userChat , completion: { success in
                    if success {
                        // upload the image:
                        
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url, completionHandler: { data,_,_ in
                                guard let data = data else {
                                    return
                                }
                                
                                let fileName = userChat.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data,fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("storage manager error \(error)")
                                    }
                                })
                            }).resume()
                        }
                    }
                })
            }
        })
        
        guard let authentication = user.authentication else {
            print("missing auth object off of google user ")
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: {authResult , error in
            guard authResult != nil, error == nil else {
                print("Failed to login with google credentials")
                return
            }
            
            print("successfully signed in with google credentials")
            NotificationCenter.default.post(name: .didLoginNotification, object: nil)
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        print("google user was disconnected")
    }
}



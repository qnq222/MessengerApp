//
//  LoginViewController.swift
//  MessengerApp
//
//  Created by Ayman  on 6/16/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    // MARK: - UI declaration:
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let mainScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let logoImageView:UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Email"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .secondarySystemBackground
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Password"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .secondarySystemBackground
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let loginBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookLoginBtn:FBLoginButton = {
        let button = FBLoginButton()
        button.layer.cornerRadius = 12
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLoginBtn: GIDSignInButton = {
        let button = GIDSignInButton()
        
        return button
    }()
    
    // MARK: - variables declaration:
    
    private var loginObserver:NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Login"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(rightButtonPressed))
        
        // adding the subviews in the controller:
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(logoImageView)
        mainScrollView.addSubview(emailTextField)
        mainScrollView.addSubview(passwordTextField)
        mainScrollView.addSubview(loginBtn)
        mainScrollView.addSubview(facebookLoginBtn)
        mainScrollView.addSubview(googleLoginBtn)
        
        
        // handle the login button press:
        loginBtn.addTarget(self,
                           action: #selector(loginBtnPressed),
                           for: .touchUpInside)
        
        // handle the textfield deleget:
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // handle the facebook login delegate:
        facebookLoginBtn.delegate = self
        
        // handle the google login:
        GIDSignIn.sharedInstance()?.presentingViewController = self
        //GIDSignIn.sharedInstance().signIn()
        
        //
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mainScrollView.frame = view.bounds
        
        let size = mainScrollView .width/3
        
        logoImageView.frame = CGRect(x: (mainScrollView.width-size)/2,
                                     y: 20,
                                     width: size,
                                     height: size)
        
        emailTextField.frame = CGRect(x: 30,
                                      y: logoImageView.bottom+10,
                                      width: mainScrollView.width-60,
                                      height: 40)
        
        passwordTextField.frame = CGRect(x: 30,
                                         y: emailTextField.bottom+10,
                                         width: mainScrollView.width-60,
                                         height: 40)
        
        loginBtn.frame = CGRect(x: 30,
                                y: passwordTextField.bottom+50,
                                width: mainScrollView.width-60,
                                height: 40)
        
        //        facebookLoginBtn.center = mainScrollView.center
        //        facebookLoginBtn.frame.origin.y = loginBtn.bottom+20
        
        facebookLoginBtn.frame = CGRect(x: 30,
                                        y: loginBtn.bottom+10,
                                        width: mainScrollView.width-60,
                                        height: 40)
        
        googleLoginBtn.frame = CGRect(x: 30,
                                      y: facebookLoginBtn.bottom+10,
                                      width: mainScrollView.width-60,
                                      height: 40)
    }
    
    @objc private func rightButtonPressed(){
        let registerVC = RegisterViewController()
        registerVC.title = "Create New Account"
        
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    
    
    // MARK: - firebase login process:
    @objc private func loginBtnPressed(){
        
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let email = emailTextField.text , let password = passwordTextField.text,
            !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                alertUserLoginError()
                return
        }
        
        spinner.show(in: view)
        
        // do the login process: with firebase:
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password , completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult , error == nil else {
                print("Login Process failed")
                return
            }
            
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { [weak self] result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                        let firstName = userData["first_name"] as? String,
                        let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("failed to get the data \(error)")
                }
            })
            
            // get the user email to save it in the database:
            UserDefaults.standard.set(email, forKey: "email")
            
            
            print("Logged in user: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Error",
                                      message: "Plaese Enter all the information correctlly to login",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Return",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
}

// MARK: - textfields delegation:
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField{
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField {
            loginBtnPressed()
        }
        return true
    }
}

// MARK: - facebook login:
extension LoginViewController:LoginButtonDelegate {
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User Failed to login with facebook")
            return
        }
        
        
        // take the logged user information:
        let facebookRequset = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email,first_name,last_name,picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil, httpMethod: .get)
        
        facebookRequset.start(completionHandler: { _, result, error in
            guard let result = result as? [String: Any],
                error == nil else {
                    print("failed to make facebook request")
                    return
            }
            print("\(result)")
            
            // to not register the user for debug.
            //return
            
            // begin to insert the logged in user to the database:
            guard let firstname = result["first_name"] as? String,
                let lastname = result["last_name"] as? String,
                let email = result["email"] as? String ,
                let picture = result["picture"] as? [String: Any],
                let data = picture["data"] as? [String: Any],
                let pictureUrl = data["url"] as? String else {
                    print("Failed to get the user info from facebook")
                    return
            }
            
            // get the user email and name to save it in the userdefault:
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstname) \(lastname)", forKey: "name")
            
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let user = User(firstName: firstname,
                                    lastName: lastname,
                                    emailAddress: email)
                    DatabaseManager.shared.insertUser(with: user , completion: { success in
                        if success {
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            print("Downloading data facebook image  ")
                            
                            URLSession.shared.dataTask(with: url, completionHandler: {data ,_ ,_  in
                                guard let data = data else {
                                    print("failed to get the image form facebook")
                                    return
                                }
                                
                                print("image downloaded, uploading...")
                                
                                // upload the image:
                                let fileName = user.profilePictureFileName
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
                    })
                }
            })
            
            
            // login the user after taking the cridentials from facebook:
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {[weak self] authResult , error in
                guard let strongSelf = self else {
                    return
                }
                guard authResult != nil , error == nil else {
                    if let error = error {
                        print("Facebook credentials login failed, MFA may be needed \(error)")
                    }
                    
                    return
                }
                
                print("user login successfully")
                print("firstname: \(firstname)")
                print("lastname: \(lastname)")
                print("email: \(email)")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no code to do not a neccery operation
    }
    
    
}

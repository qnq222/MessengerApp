//
//  LoginViewController.swift
//  MessengerApp
//
//  Created by Ayman  on 6/16/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import FirebaseAuth
class LoginViewController: UIViewController {
    
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
        textField.backgroundColor = .white
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
        textField.backgroundColor = .white
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Login"
        view.backgroundColor = .white
        
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
        
        // handle the login button press:
        loginBtn.addTarget(self,
                           action: #selector(loginBtnPressed),
                           for: .touchUpInside)
        
        // handle the textfield deleget:
        emailTextField.delegate = self
        passwordTextField.delegate = self
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
    }
    
    @objc private func rightButtonPressed(){
        let registerVC = RegisterViewController()
        registerVC.title = "Create New Account"
        
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    
    
    @objc private func loginBtnPressed(){
        
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let email = emailTextField.text , let password = passwordTextField.text,
            !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                alertUserLoginError()
                return
        }
        // do the login process: with firebase:
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password , completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            guard let result = authResult , error == nil else {
                print("Login Process failed")
                return
            }
            
            let user = result.user
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

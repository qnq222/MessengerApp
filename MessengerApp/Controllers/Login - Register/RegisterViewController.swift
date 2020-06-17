//
//  RegisterViewController.swift
//  MessengerApp
//
//  Created by Ayman  on 6/16/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import FirebaseAuth


class RegisterViewController: UIViewController {
    
    private let mainScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let userImageView:UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let firstNameTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "First Name"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        return textField
    }()
    
    private let lastNameTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Last Name"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        return textField
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
    
    
    
    private let registerBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Register ", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create New Account"
        view.backgroundColor = .white
        
        // adding the subviews in the controller:
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(userImageView)
        mainScrollView.addSubview(firstNameTextField)
        mainScrollView.addSubview(lastNameTextField)
        mainScrollView.addSubview(emailTextField)
        mainScrollView.addSubview(passwordTextField)
        mainScrollView.addSubview(registerBtn)
        
        
        // handle the login button press:
        registerBtn.addTarget(self,
                              action: #selector(registerBtnPressed),
                              for: .touchUpInside)
        
        // handle the imageView gesture:
        userImageView.isUserInteractionEnabled = true
        //mainScrollView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(userImageViewPressed))
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        userImageView.addGestureRecognizer(gesture)
        
        // handle the textfield deleget:
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mainScrollView.frame = view.bounds
        let size = mainScrollView .width/3
        userImageView.frame = CGRect(x: (mainScrollView.width-size)/2,
                                     y: 20,
                                     width: size,
                                     height: size)
        userImageView.layer.cornerRadius = userImageView.width/2
        
        firstNameTextField.frame = CGRect(x: 30,
                                          y: userImageView.bottom+10,
                                          width: mainScrollView.width-60,
                                          height: 40)
        
        lastNameTextField.frame = CGRect(x: 30,
                                         y: firstNameTextField.bottom+10,
                                         width: mainScrollView.width-60,
                                         height: 40)
        
        emailTextField.frame = CGRect(x: 30,
                                      y: lastNameTextField.bottom+10,
                                      width: mainScrollView.width-60,
                                      height: 40)
        
        passwordTextField.frame = CGRect(x: 30,
                                         y: emailTextField.bottom+10,
                                         width: mainScrollView.width-60,
                                         height: 40)
        
        registerBtn.frame = CGRect(x: 30,
                                   y: passwordTextField.bottom+50,
                                   width: mainScrollView.width-60,
                                   height: 40)
    }
    
    
    @objc private func registerBtnPressed(){
        
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let firstName = firstNameTextField.text,
            let lastName = lastNameTextField.text,
            let email = emailTextField.text ,
            let password = passwordTextField.text,
            !firstName.isEmpty, !lastName.isEmpty,
            !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                alertUserLoginError()
                return
        }
        
        // do the register process: with firebase.
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exsit in
            guard let strongSelf = self else {
                return
            }
            guard !exsit else {
                // user aleady exsits
                strongSelf.alertUserLoginError(message: "User aleady exsits")
                return
            }
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: {authResult, error in
                guard authResult != nil, error == nil else {
                    print("Error")
                    return
                }
                DatabaseManager.shared.insertUser(with: User(firstName: firstName,
                                                             lastName: lastName,
                                                             emailAddress: email))
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    func alertUserLoginError(message: String = "Plaese Enter all the information correctlly to register"){
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Return",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func userImageViewPressed(){
        print("change photo ")
        presentPhotoActionSheet()
    }
    
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstNameTextField:
            lastNameTextField.becomeFirstResponder()
        case lastNameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            registerBtnPressed()
        default:
            print("Error")
        }
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Change Profile Photo",
                                            message: "You either select a photo or you can take a photo",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "Select a Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                self?.presentPhotoPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Take a Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                self?.presentCamara()
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamara(){
        let camaraVC = UIImagePickerController()
        camaraVC.sourceType = .camera
        camaraVC.delegate = self
        camaraVC.allowsEditing = true
        present(camaraVC, animated: true)
    }
    
    func presentPhotoPicker() {
        let photoPicker = UIImagePickerController()
        photoPicker.sourceType = .photoLibrary
        photoPicker.delegate = self
        photoPicker.allowsEditing = true
        present(photoPicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info.keys)
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.userImageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

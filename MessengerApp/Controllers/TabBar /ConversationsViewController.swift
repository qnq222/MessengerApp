//
//  ViewController.swift
//  MessengerApp
//
//  Created by Ayman  on 6/16/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    private let sppiner = JGProgressHUD(style: .dark)
    
    private let conversationTableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "conversationCell")
        return tableView
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize:  21, weight: .heavy)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(conversationTableView)
        view.addSubview(noConversationLabel)
        setUpTableView()
        fetchConversations()
        
        
        // setup a button to allow the user to create a new conversation:
        //.add but .compose is more meaningful.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(addConversationPressed))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // add a frame to the tableview to show:
        conversationTableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginVC = LoginViewController()
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func setUpTableView(){
        conversationTableView.delegate = self
        conversationTableView.dataSource = self
    }
    
    private func fetchConversations() {
        conversationTableView.isHidden = false
    }
    
    @objc private func addConversationPressed(){
        let newConversationVC = NewConversationViewController()
        newConversationVC.completion = { [weak self] result in
            print("\(result)")
            self?.createNewConversation(result: result)
        }
        let nav = UINavigationController(rootViewController: newConversationVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func createNewConversation(result: [String: String]){
        guard let name = result["name"],
            let email = result["email"] else {
                print("error creating new conversation")
            return
        }
        
        
        let chatCV = ChatViewController(with: email)
        chatCV.isNewConversation = true
        chatCV.title = name
        chatCV.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatCV, animated: true)
    }
}

extension ConversationsViewController: UITableViewDelegate , UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell", for: indexPath)
        cell.textLabel?.text = "Test..."
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let chatCV = ChatViewController(with: "a@a.com")
        chatCV.title = "Ayman Ali"
        chatCV.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatCV, animated: true )
    }
    
}


 

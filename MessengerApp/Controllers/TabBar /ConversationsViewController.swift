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
    
    private var conversations = [Conversation]()
    
    private let conversationTableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(ConversationTableViewCell.self,
                           forCellReuseIdentifier: ConversationTableViewCell.identifier)
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
         
        startListeningForConversations()
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
        let chatCV = ChatViewController(with: email, id: nil)
        chatCV.isNewConversation = true
        chatCV.title = name
        chatCV.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatCV, animated: true)
    }
    
    /// to fetch the changes in databse in real time
    private func startListeningForConversations(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        print("starting conversations fetch")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail , completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print("successfully got the conversation models")
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.conversationTableView.reloadData()
                }
                
            case .failure(let error):
                print("error getting the conversations form the database: \(error)")
            }
        })
    }
}

extension ConversationsViewController: UITableViewDelegate , UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
//        cell.textLabel?.text = "Test..."
//        cell.accessoryType = .disclosureIndicator
        
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        let chatCV = ChatViewController(with: model.otherUserEmail , id: model.id)
        chatCV.title = model.reciverName
        chatCV.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatCV, animated: true )
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // because i made the user image in the cell 100 so i want 10 top and 10 bottom
        return 120
    }
    
}


 

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
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(conversationTableView)
        view.addSubview(noConversationLabel)
        
        // setup a button to allow the user to create a new conversation:
        //.add but .compose is more meaningful.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(addConversationPressed))
        setUpTableView()
        fetchConversations()
        startListeningForConversations()
        
        //
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConversations()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // add a frame to the tableview to show:
        conversationTableView.frame = view.bounds
        
        noConversationLabel.frame = CGRect(x: 10,
                                            y: (view.height-100)/2,
                                            width: view.width-20,
                                            height: 100)
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
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                strongSelf.createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: newConversationVC)
        present(navVC, animated: true)
    }
    
    //
    private func createNewConversation(result: SearchResult){
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email )
        
        // check in database if conversation with these two user exists
        // if it does reuse conversation id
        // otherwise use exsiting code
        
        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let conversationId):
                let chatCV = ChatViewController(with: email, id: conversationId)
                chatCV.isNewConversation = false
                chatCV.title = name
                chatCV.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(chatCV, animated: true)
            case .failure(_):
                let chatCV = ChatViewController(with: email, id: nil)
                chatCV.isNewConversation = true
                chatCV.title = name
                chatCV.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(chatCV, animated: true)
            }
        })
        
    }
    
    /// to fetch the changes in databse in real time
    private func startListeningForConversations(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("starting conversations fetch")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail , completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print("successfully got the conversation models")
                guard !conversations.isEmpty else {
                    self?.conversationTableView.isHidden = true
                    self?.noConversationLabel.isHidden = false
                    return
                }
                self?.noConversationLabel.isHidden = true
                self?.conversationTableView.isHidden = false
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.conversationTableView.reloadData()
                }
                
            case .failure(let error):
                self?.conversationTableView.isHidden = true
                self?.noConversationLabel.isHidden = false
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
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let chatCV = ChatViewController(with: model.otherUserEmail , id: model.id)
        chatCV.title = model.name
        chatCV.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatCV, animated: true )
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // because i made the user image in the cell 100 so i want 10 top and 10 bottom
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete conversation:
            let conversationId = conversations[indexPath.row].id
            
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { [weak self] success in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            })
            tableView.endUpdates()
        }
    }
    
}


 

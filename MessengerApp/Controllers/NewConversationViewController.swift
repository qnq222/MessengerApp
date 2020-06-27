//
//  NewConversationViewController.swift
//  MessengerApp
//
//  Created by Ayman  on 6/16/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {

    public var completion: ((SearchResult) -> (Void))?
    
    //MARK: - UI Decleration:
    private let sppiner = JGProgressHUD(style: .dark)
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search For Users"
        return searchBar
    }()
    
    private let userTableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(NewConversationCell.self,
                           forCellReuseIdentifier: NewConversationCell.identifier )
        return tableView
    }()
    
    private let noResultsLB: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results."
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .heavy)
        return label
    }()
    
    // MARK: - Variables Decleration:
    private var users = [[String: String]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    
    // MARK: - viewDidLoad:
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // add the subviews:
        view.addSubview(noResultsLB)
        view.addSubview(userTableView)
        
        // setup the tableView:
        userTableView.delegate = self
        userTableView.dataSource = self
        
        searchBar.delegate = self
        // to put the search bar in the top of the view.
        // so we don't manually frame it and put constrains in it.
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(cancelPressed))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        userTableView.frame = view.bounds
        noResultsLB.frame = CGRect(x: view.width/4,
                                   y: (view.height-200)/2,
                                   width: view.width/2,
                                    height: 200)
    }
    
    
    @objc private func cancelPressed(){
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - NewConversationViewController extensions:
extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //
        guard let text = searchBar.text , !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        print("user searched...")
        searchBar.resignFirstResponder()
        results.removeAll()
        sppiner.show(in: view)
        
        searchUser(query: text)
    }
    
    func searchUser(query: String){
        // check if the array has the firebase results:
        if hasFetched {
        // if it does filter
            filterUser(with: query)
        }else {
        // if not, fetch the data form firebase the filter the results.
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUser(with: query)
                case .failure(let error):
                    print("failed to get user: \(error)")
                }
            })
        }
    }
    
    func filterUser(with term: String){
        // update the UI: either show the results or show no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
            hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        self.sppiner.dismiss()
        
        let results: [SearchResult] = users.filter({
            guard let email = $0["email"], email != safeEmail else {
                    return false
            }
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"],
                let name = $0["name"] else {
                return nil
            }
            return SearchResult(name: name, email: email)
        })
        self.results = results
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            noResultsLB.isHidden = false
            userTableView.isHidden = true
        }else {
            noResultsLB.isHidden = true
            userTableView.isHidden = false
            userTableView.reloadData()
        }
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier,
                                                 for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversavtion:
        let targetUserResult = results[indexPath.row]
        
        dismiss(animated: true, completion: { [weak self] in
            // ? because its an opitional.
            self?.completion?(targetUserResult)
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90 
    }
    
}

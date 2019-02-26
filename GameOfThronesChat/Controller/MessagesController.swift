//
//  ViewController.swift
//  GameOfThronesChat
//
//  Created by MikeLi on 2019-02-19.
//  Copyright © 2019 MikeLi. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {
    
    let cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogOut))
        
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
    }
    
    var messages: [Message] = []
    var messagesDistionary: [String: Message] = [:]
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let userId = snapshot.key
            let userRef = ref.child(userId)
            
            userRef.observe(.childAdded, with: { (messageSnapshot) in
                let messageId = messageSnapshot.key
                
                self.fetchMessagesWithMessageId(messageId: messageId)

            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    private func fetchMessagesWithMessageId(messageId: String) {
        let messageReference = Database.database().reference().child("messages").child(messageId)
        
        messageReference.observeSingleEvent(of: .value, with: { (dataSnapshot) in
            if let dict = dataSnapshot.value as? [String: Any] {
                let message = Message(dictionary: dict)
                    
                    if let chatPartnerId = message.chatPartnerId() {
                        self.messagesDistionary[chatPartnerId] = message
                    }
                    
                    self.attemptReloadTable()
            }
        })
    }
    
    private func attemptReloadTable() {
        self.timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handleReloadTable), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
        
    @objc func handleReloadTable() {
        
        self.messages = Array(self.messagesDistionary.values)
        self.messages.sorted(by: { (message1, message2) -> Bool in
            return Double(message1.timestamp!)! > Double(message2.timestamp!)!
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessagesController()
        newMessageController.messagesController = self
        let navigationController = UINavigationController(rootViewController: newMessageController)
        present(navigationController, animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogOut), with: nil, afterDelay: 0)
            handleLogOut()
        } else {
            
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
                Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                guard let name = dict["name"] as? String else { return }
                guard let email = dict["email"] as? String else { return }
                guard let profileImageUrl = dict["profileImageUrl"] as? String else { return }
                let user = User(id: snapshot.key, name: name, email: email, profileImageUrl: profileImageUrl)
                self.setupNavBarWithUser(user: user)
            }
        }
    }
    
    func setupNavBarWithUser(user: User) {
        messages.removeAll()
        messagesDistionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        let profileImageView = UIImageView()
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        titleView.addSubview(profileImageView)
        profileImageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        let nameLabel = UILabel()
        nameLabel.text = user.name
        
        titleView.addSubview(nameLabel)
        nameLabel.frame = CGRect(x: 48, y: 0, width: nameLabel.intrinsicContentSize.width, height: 40)

        titleView.frame = CGRect(x: 0, y: 0, width: nameLabel.frame.origin.x + nameLabel.frame.width, height: 40)
        self.navigationItem.titleView = titleView
        
//        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatControllerForUser(user:))))
    }
    
    @objc func handleLogOut() {
        do {
            try Auth.auth().signOut()
        } catch let logOutError {
            print(logOutError)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }
    
    @objc func showChatControllerForUser(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
            
       return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else { return }
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dict = snapshot.value as? [String: Any] else { return }
            guard let name = dict["name"] as? String else { return }
            guard let email = dict["email"] as? String else { return }
            guard let profileImageUrl = dict["profileImageUrl"] as? String else { return }
            let user = User(id: chatPartnerId, name: name, email: email, profileImageUrl: profileImageUrl)
            
            self.showChatControllerForUser(user: user)
        }, withCancel: nil)
    }
    
}


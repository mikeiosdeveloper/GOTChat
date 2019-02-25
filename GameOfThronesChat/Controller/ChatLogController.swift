//
//  ChatLogController.swift
//  GameOfThronesChat
//
//  Created by MikeLi on 2019-02-21.
//  Copyright © 2019 MikeLi. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var messages:[Message] = []
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else { return }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messageRef = Database.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: { (messageSnapshot) in
                guard let dict = messageSnapshot.value as? [String: Any] else { return }
                if let fromId = dict["fromId"] as? String, let toId = dict["toId"] as? String, let text = dict["text"] as? String, let timeInterval = dict["timestamp"] as? String {
                    let message = Message(fromId: fromId, toIDd: toId, text: text, timeInterval: timeInterval, imageUrl: nil)
                    
                        self.messages.append(message)
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                } else if let fromId = dict["fromId"] as? String, let toId = dict["toId"] as? String, let imageUrl = dict["imageUrl"] as? String, let timeInterval = dict["timestamp"] as? String {
                    let message = Message(fromId: fromId, toIDd: toId, text: nil, timeInterval: timeInterval, imageUrl: imageUrl)
                    
                    self.messages.append(message)
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            })
        }, withCancel: nil)
    }
    
    lazy var inputTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter Message"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        
        return tf
    }()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
         super.viewDidLoad()

        collectionView.backgroundColor = UIColor.white
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView.alwaysBounceVertical = true
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView.keyboardDismissMode = .interactive
        
        // Apple recommended way to manipulate keyboard:
        //       setupInputComponents()
        //       setupKeyboardObserver()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // Use inputAccessoryView to manipulate keyboard:
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "upload_image_icon")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadImage)))
        
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(uploadImageView)
        
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -15).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(inputTextField)
        
        inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(lessThanOrEqualTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(lessThanOrEqualTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        
        return containerView
    }()
    
    @objc func handleUploadImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImage: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        if let selectedImage = selectedImage {
            uploadImageToFirebaseStorage(selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadImageToFirebaseStorage(_ image: UIImage) {
        let imageName = UUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = image.jpegData(compressionQuality: 0.2) {
            ref.putData(uploadData, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error)
                    return
                }
                
                ref.downloadURL(completion: { (url, error) in
                    guard let url = url else { return }
                    
                    let imageUrl = url.absoluteString
                    
                    self.sendMessageWithImage(imageUrl: imageUrl)
                })
            }
        }
    }
    
    func sendMessageWithImage(imageUrl: String) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        if let message = inputTextField.text, let user = self.user, let fromId = Auth.auth().currentUser?.uid {
            let toId = user.id!
            let timestamp = String(Date().timeIntervalSince1970)
            let values = ["imageUrl": imageUrl, "toId": toId, "fromId": fromId, "timestamp": timestamp]
            childRef.updateChildValues(values) { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                
                self.inputTextField.text = nil
                
                let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
                
                if let messageId = childRef.key {
                    userMessagesRef.updateChildValues([messageId: 1])
                    
                    let receiptentUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
                    receiptentUserMessageRef.updateChildValues([messageId: 1])
                }
            }
        }

    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    
    /*
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardWillShow(notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! TimeInterval
        
        containerBottomAnchor?.constant -= keyboardFrame.height
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    @objc func handleKeyboardWillHide(notification: Notification) {
        containerBottomAnchor?.constant = 0
        
        let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! TimeInterval
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
 
 */
 
    
    private func setFlowLayout(height: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: view.frame.width, height: height)
        collectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude)

        return text.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerBottomAnchor: NSLayoutConstraint?
    /*
    func setupInputComponents() {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomAnchor!.isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -15).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(inputTextField)
        
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 15).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(lessThanOrEqualTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(lessThanOrEqualTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    }
    */
    
    @objc func handleSend() {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        if let message = inputTextField.text, let user = self.user, let fromId = Auth.auth().currentUser?.uid {
            let toId = user.id!
            let timestamp = String(Date().timeIntervalSince1970)
            let values = ["text": message, "toId": toId, "fromId": fromId, "timestamp": timestamp]
            childRef.updateChildValues(values) { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                
                self.inputTextField.text = nil
                
                let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
                
                if let messageId = childRef.key {
                     userMessagesRef.updateChildValues([messageId: 1])
                    
                    let receiptentUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
                    receiptentUserMessageRef.updateChildValues([messageId: 1])
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.item]
        
        if let text = message.text {
            cell.textView.text = text
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
        }
        
        setupCell(cell: cell, message: message)
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
        } else {
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80

        if let text = messages[indexPath.item].text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageUrl = messages[indexPath.item].imageUrl {
          //  height = estimateFrameForText(text: text).height + 20
        }

        return CGSize(width: view.frame.width, height: height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
}

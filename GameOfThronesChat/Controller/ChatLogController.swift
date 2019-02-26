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
                    let message = Message(dictionary: dict)
                    self.messages.append(message)
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        
                        if self.messages.count > 0 {
                            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        setupKeyboardDidShowObserver()
        
        // Apple recommended way to manipulate keyboard:
        //       setupInputComponents()
        //       setupKeyboardObserver()
    }
    
    func setupKeyboardDidShowObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidshow), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc private func handleKeyboardDidshow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    // Use inputAccessoryView to manipulate keyboard:
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
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
                    
                    self.sendMessageWithImage(imageUrl: imageUrl, image: image)
                })
            }
        }
    }
    
    func sendMessageWithImage(imageUrl: String, image: UIImage) {
        let properties:[String: Any] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String: Any]) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        if let user = self.user, let fromId = Auth.auth().currentUser?.uid {
            let toId = user.id!
            let timestamp = String(Date().timeIntervalSince1970)
            var values: [String: Any] = ["toId": toId, "fromId": fromId, "timestamp": timestamp]
            
            for (key, value) in properties {
                values[key] = value
            }
            
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
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

    @objc func handleSend() {
        if let text = inputTextField.text {
            let properties: [String: Any] = ["text": text]
            sendMessageWithProperties(properties: properties)
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
    
    // MARK: - CollectionView DataSource:
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        
        if let text = message.text {
            cell.textView.text = text
            cell.textView.isHidden = false
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
        } else if let _ = message.imageUrl {
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
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
        let message = messages[indexPath.item]

        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth, let imageHeight = message.imageHeight {
          height = imageHeight / imageWidth * 200
        }

        return CGSize(width: view.frame.width, height: height)
    }
    
    //MARK: - Image Zooming Logic:
    
    var startingFrame: CGRect?
    var backgroundView = UIView()
    var startingImageView = UIImageView()
    
    func performZoomInForImageView(startingImageView: UIImageView) {
        
        self.startingImageView = startingImageView
        self.startingImageView.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        guard let startingFrame = startingFrame else { return }
        
        let zoomingImageView = UIImageView(frame: startingFrame)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut(tapGesture:))))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            backgroundView = UIView(frame: keyWindow.frame)
            backgroundView.backgroundColor = UIColor.black
            backgroundView.alpha = 0
            keyWindow.addSubview(backgroundView)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.backgroundView.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = startingFrame.height / startingFrame.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }, completion: nil)
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.backgroundView.alpha = 0
                self.inputContainerView.alpha = 1
            }) { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView.isHidden = false
            }
        }
    }
    
    // Methods for apple recommended way to handle keyboard:
    /*
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
    
}

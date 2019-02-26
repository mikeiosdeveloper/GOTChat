//
//  ChatMessageCell.swift
//  GameOfThronesChat
//
//  Created by MikeLi on 2019-02-23.
//  Copyright © 2019 MikeLi. All rights reserved.
//

import UIKit
import AVFoundation

class ChatMessageCell: UICollectionViewCell {
    
    var message: Message?
    var chatLogController: ChatLogController?
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        
        return aiv
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "play"), for: .normal)
        button.tintColor = UIColor.white
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(handlePalyVideo), for: .touchUpInside)
        
        return button
    }()
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    @objc func handlePalyVideo() {
        if let videoUrlString = message?.videoUrl, let url = URL(string: videoUrlString) {
            player = AVPlayer(url: url)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = bubbleView.bounds
            bubbleView.layer.addSublayer(playerLayer!)
            player?.play()
            activityIndicatorView.startAnimating()
            playButton.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        activityIndicatorView.stopAnimating()
    }
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = UIColor.clear
        tv.textColor = UIColor.white
        tv.isScrollEnabled = false
        tv.isEditable = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        
        return tv
    }()
    
    static let blueColor = UIColor(r: 0, g: 137, b: 249)
    
    let bubbleView: UIView = {
        let bv = UIView()
        bv.backgroundColor = blueColor
        bv.layer.cornerRadius = 16
        bv.layer.masksToBounds = true
        bv.translatesAutoresizingMaskIntoConstraints = false
        
        return bv
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    lazy var messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap(tapGesture:))))
        
        return imageView
    }()
    
    @objc func handleZoomTap(tapGesture: UITapGestureRecognizer) {
        
        if message?.videoUrl != nil {
            return
        }
        
        if let imageToZoom = tapGesture.view as? UIImageView {
            self.chatLogController?.performZoomInForImageView(startingImageView: imageToZoom)
        }
    }
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleLeftAnchor: NSLayoutConstraint?
    var bubbleRightAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        bubbleView.addSubview(messageImageView)
        
        bubbleRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleRightAnchor?.isActive = true
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messageImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        messageImageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        bubbleView.addSubview(playButton)
        bubbleView.addSubview(activityIndicatorView)
        
        playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        activityIndicatorView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicatorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

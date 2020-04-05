//
//  ChatListViewController.swift
//  ChatAppWithFirebase
//
//  Created by Uske on 2020/03/15.
//  Copyright © 2020 Uske. All rights reserved.
//

import UIKit
import Firebase
import Nuke

class ChatListViewController: UIViewController {
    
    private let cellId = "cellId"
    private var chatroooms = [ChatRoom]()
    
    private var user: User? {
        didSet {
            navigationItem.title = user?.username
        }
    }
    
    @IBOutlet weak var chatListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        confirmLoggedInUser()
        fetchLoginUserInfo()
        fetchChatroomsInfoFromFirestore()
    }
    
    private func fetchChatroomsInfoFromFirestore() {
        Firestore.firestore().collection("chatRooms")
            .addSnapshotListener { (snapshots, err) in
                if let err = err {
                    print("ChatRooms情報の取得に失敗しました。\(err)")
                    return
                }
                
                snapshots?.documentChanges.forEach({ (documentChange) in
                    switch documentChange.type {
                    case .added:
                        self.handleAddedDocumentChange(documentChange: documentChange)
                    case .modified, .removed:
                        print("nothing to do")
                    }
                })
        }
        
    }
    
    private func handleAddedDocumentChange(documentChange: DocumentChange) {
        let dic = documentChange.document.data()
        let chatroom = ChatRoom(dic: dic)
        chatroom.documentId = documentChange.document.documentID
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let isConatin = chatroom.memebers.contains(uid)
        
        if !isConatin { return }
        
        chatroom.memebers.forEach { (memberUid) in
            if memberUid != uid {
                Firestore.firestore().collection("users").document(memberUid).getDocument { (snaoshot, err) in
                    if let err = err {
                        print("ユーザー情報の取得に失敗しました。\(err)")
                        return
                    }
                    
                    guard let dic = snaoshot?.data() else { return }
                    let user = User(dic: dic)
                    user.uid = documentChange.document.documentID
                    
                    chatroom.partnerUser = user
                    self.chatroooms.append(chatroom)
                    print("self.chatroooms.count: ", self.chatroooms.count)
                    self.chatListTableView.reloadData()
                    
                }
            }
        }
    }
    
    private func setupViews() {
        chatListTableView.tableFooterView = UIView()
        chatListTableView.delegate = self
        chatListTableView.dataSource = self
        
        navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
        navigationItem.title = "トーク"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        let rigntBarButton = UIBarButtonItem(title: "新規チャット", style: .plain, target: self, action: #selector(tappedNavRightBarButton))
        navigationItem.rightBarButtonItem = rigntBarButton
        navigationItem.rightBarButtonItem?.tintColor = .white
        
    }
    
    private func confirmLoggedInUser() {
        if Auth.auth().currentUser?.uid == nil {
            let storyboar = UIStoryboard(name: "SignUp", bundle: nil)
            let signUpViewController = storyboar.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
            signUpViewController.modalPresentationStyle = .fullScreen
            self.present(signUpViewController, animated: true, completion: nil)
        }
    }
    
    @objc private func tappedNavRightBarButton() {
        let storyboard = UIStoryboard.init(name: "UserList", bundle: nil)
        let userListViewControlelr = storyboard.instantiateViewController(withIdentifier: "UserListViewController")
        let nav = UINavigationController(rootViewController: userListViewControlelr)
        self.present(nav, animated: true, completion: nil)
    }
    
    private func fetchLoginUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in
            if let err = err {
                print("ユーザー情報の取得に失敗しました。\(err)")
                return
            }
            
            guard let snapshot = snapshot, let dic = snapshot.data() else { return }
            
            let user = User(dic: dic)
            self.user = user
        }
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatroooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatListTableViewCell
        cell.chatroom = chatroooms[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tapped table view")
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as! ChatRoomViewController
        chatRoomViewController.user = user
        chatRoomViewController.chatroom = chatroooms[indexPath.row]
        navigationController?.pushViewController(chatRoomViewController, animated: true)
    }
    
}

class ChatListTableViewCell: UITableViewCell {
    
//    var user: User? {
//        didSet {
//            if let user = user {
//                partnerLabel.text = user.username
//
//                //            userImageView.image = user?.profileImageUrl
//                dateLabel.text = dateFormatterForDateLabel(date: user.createdAt.dateValue())
//                latestMessageLabel.text = user.email
//            }
//        }
//    }
    
    var chatroom: ChatRoom? {
        didSet {
            if let chatroom = chatroom {
                partnerLabel.text = chatroom.partnerUser?.username
                
                guard let url = URL(string: chatroom.partnerUser?.profileImageUrl ?? "") else { return }
                Nuke.loadImage(with: url, into: userImageView)
                
                dateLabel.text = dateFormatterForDateLabel(date: chatroom.createdAt.dateValue())
            }
        }
    }
    
    @IBOutlet weak var partnerLabel: UILabel!
    @IBOutlet weak var latestMessageLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = 30
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func dateFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
}


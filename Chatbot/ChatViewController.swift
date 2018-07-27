//
//  ChatViewController.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

struct UserChatInfo {
    var userID: Int!
    var nickname: String!
    var phoneNumber: Int!
    var image_URL: String!
    var msg: String!
    var date: String!
    var isRead: Bool!
    var sender_ID: Int!
}

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tblChat: UITableView!
    
    @IBOutlet weak var lblOtherUserActivityStatus: UILabel!
    
    @IBOutlet weak var tvMessageEditor: UITextView!
    
    @IBOutlet weak var conBottomEditor: NSLayoutConstraint!
    
    @IBOutlet weak var lblNewsBanner: UILabel!
    
    var nickname: String!
    
    var chatMessages = [[String: AnyObject]]()
    
    var bannerLabelTimer: Timer!
    
    var today:String!
    
    // MARK: Custom Properties
    
    var userID: Int!
    
    var userchatInfo: [UserChatInfo]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tvMessageEditor.delegate = self

         NotificationCenter.default.addObserver(self,
            selector: #selector(handleKeyboardDidShowNotification(notification:)),
            name: .didShowNotification,
            object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidHideNotification(notification:)), name: .didhidenotification, object: nil)
        
       // NotificationCenter.default.addObserver(self, selector: Selector(("handleConnectedUserUpdateNotification:")), name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(handleConnectedUserUpdateNotification(notification:)), name: .userWasConnectedNotification, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDisconnectedUserUpdateNotification(notification:)), name: .userwasDisconnectnotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserTypingNotification(notification:)), name: .userTypingnotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(self.handleUserTypingNotification), name: NSNotification.Name(rawValue: "userTypingNotification"), object: nil)

        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.down
        swipeGestureRecognizer.delegate = self
        view.addGestureRecognizer(swipeGestureRecognizer)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTableView()
        configureNewsBannerLabel()
        configureOtherUserActivityLabel()
        
        tvMessageEditor.delegate = self
        tvMessageEditor.inputAccessoryView = UIView()
        
        userID = 1
        self.getUserData()

    }
    
    //Get values from local DB here...
    func getUserData() -> Void {
        
                DispatchQueue.main.async {
                    self.userchatInfo =  DBManager.shared.loadMovies(withId: self.userID)
                    print(self.userchatInfo)
                    
                    for chat in self.userchatInfo
                    {
                        var messageDictionary = [String: AnyObject]()
                        messageDictionary["nickname"] = chat.nickname as AnyObject
                        messageDictionary["msg"] = chat.msg  as AnyObject
                        messageDictionary["date"] = chat.date as AnyObject
                        
                        self.chatMessages.append(messageDictionary)
                    }
                    
                        self.tblChat.reloadData()
                        self.scrollToBottom()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SocketIOManager.sharedInstance.getChatMessage { (messageInfo) -> Void in
            DispatchQueue.main.async {
                self.chatMessages.append(messageInfo)
                DBManager.shared.insertUserData(nickname: messageInfo["nickname"] as! String, userID: 1, phoneNumber: 9, userImage: "", message: messageInfo["msg"] as! String, isRead: true, senderID: 2, dateTime: messageInfo["date"] as! String)
                self.tblChat.reloadData()
                self.scrollToBottom()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self .dismissKeyboard()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //Current Date and time
    func getTodayString() -> String{
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        let today_string = String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
        
        return today_string
        
    }



    
    // MARK: IBAction Methods
    
    @IBAction func sendMessage(_ sender: Any) {
        if tvMessageEditor.text.count > 0 {
            today = getTodayString()
            SocketIOManager.sharedInstance.sendMessage(msg: tvMessageEditor.text!, withNickname: nickname)
            DBManager.shared.insertUserData(nickname: nickname, userID: 1, phoneNumber: 9, userImage: "", message: tvMessageEditor.text!, isRead: true, senderID: 2, dateTime: today)
            tvMessageEditor.text = ""
            tvMessageEditor.resignFirstResponder()
        }
    }
    
    

    
    // MARK: Custom Methods
    
    func configureTableView() {
        tblChat.delegate = self
        tblChat.dataSource = self
        tblChat.register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "idCellChat")
        tblChat.estimatedRowHeight = 90.0
        tblChat.rowHeight = UITableViewAutomaticDimension
        tblChat.tableFooterView = UIView.init()
    }
    
    
    func configureNewsBannerLabel() {
        lblNewsBanner.layer.cornerRadius = 15.0
        lblNewsBanner.clipsToBounds = true
        lblNewsBanner.alpha = 0.0
    }
    
    
    func configureOtherUserActivityLabel() {
        lblOtherUserActivityStatus.isHidden = true
        lblOtherUserActivityStatus.text = ""
    }
    
    
    @objc func handleKeyboardDidShowNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                conBottomEditor.constant = keyboardFrame.size.height
                view.layoutIfNeeded()
            }
        }
    }
    
    
    @objc func handleKeyboardDidHideNotification(notification: NSNotification) {
        conBottomEditor.constant = 0
        view.layoutIfNeeded()
    }
    
    
    func scrollToBottom() {
        //let delay = 0.1 * Double(NSEC_PER_SEC)

        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
        //dispatch_after(dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(delay)), dispatch_get_main_queue()) { () -> Void in
            if self.chatMessages.count > 0 {
                let lastRowIndexPath = IndexPath(row: self.chatMessages.count - 1, section: 0)
                self.tblChat.scrollToRow(at: lastRowIndexPath, at: UITableViewScrollPosition.bottom, animated: true)
            }
        }
    }
    
    
    func showBannerLabelAnimated() {
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 1.0
            
            }) { (finished) -> Void in
                self.bannerLabelTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector:(#selector(ChatViewController.hideBannerLabel)), userInfo: nil, repeats: false)
        }
    }
    
    //Selector(("hideBannerLabel")
    @objc func hideBannerLabel() {
        if bannerLabelTimer != nil {
            bannerLabelTimer.invalidate()
            bannerLabelTimer = nil
        }
        
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 0.0
            
            }) { (finished) -> Void in
        }
    }

    
    
    @objc func dismissKeyboard() {
        if tvMessageEditor.isFirstResponder {
            tvMessageEditor.resignFirstResponder()
            
            SocketIOManager.sharedInstance.sendStopTypingMessage(nickname: nickname)
        }
    }
    
    
    @objc func handleConnectedUserUpdateNotification(notification: NSNotification) {
        let connectedUserInfo = notification.object as! [String: AnyObject]
        let connectedUserNickname = connectedUserInfo["nickname"] as? String
        lblNewsBanner.text = "User \(connectedUserNickname!.uppercased()) was just connected."
        showBannerLabelAnimated()
    }
    
    
    @objc func handleDisconnectedUserUpdateNotification(notification: NSNotification) {
        let disconnectedUserNickname = notification.object as! String
        lblNewsBanner.text = "User \(disconnectedUserNickname.uppercased()) has left."
        showBannerLabelAnimated()
    }
    
    
    @objc func handleUserTypingNotification(notification: NSNotification) {
        if let typingUsersDictionary = notification.object as? [String: AnyObject] {
            var names = ""
            var totalTypingUsers = 0
            for (typingUser, _) in typingUsersDictionary {
                if typingUser != nickname {
                    names = (names == "") ? typingUser : "\(names), \(typingUser)"
                    totalTypingUsers += 1
                }
            }
            
            if totalTypingUsers > 0 {
                let verb = (totalTypingUsers == 1) ? "is" : "are"
                
                lblOtherUserActivityStatus.text = "\(names) \(verb) now typing a message..."
                lblOtherUserActivityStatus.isHidden = false
            }
            else {
                lblOtherUserActivityStatus.isHidden = true
            }
        }
        
    }
    
    
    // MARK: UITableView Delegate and Datasource Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellChat", for: indexPath as IndexPath) as! ChatCell
        
        let currentChatMessage = chatMessages[indexPath.row]
        let senderNickname = currentChatMessage["nickname"] as! String
        let message = currentChatMessage["msg"] as! String
        let messageDate = currentChatMessage["date"] as! String
        
        cell.layer.cornerRadius = 15
        cell.layer.masksToBounds = true
        if senderNickname == nickname {
            cell.lblChatMessage.textAlignment = NSTextAlignment.right
            cell.lblMessageDetails.textAlignment = NSTextAlignment.right
            cell.lblChatMessage.textColor = UIColor.white
            cell.backView.backgroundColor = lblNewsBanner.backgroundColor//UIColor(red: 0, green: 122, blue: 255, alpha: 1)
            
        }
        
        cell.lblChatMessage.text = message
        cell.lblMessageDetails.text = "by \(senderNickname.uppercased()) @ \(messageDate)"
        
        cell.lblChatMessage.textColor = UIColor.darkGray
        
        return cell
    }
    
    
    // MARK: UITextViewDelegate Methods
    
    //private func textViewShouldBeginEditing(textView: UITextView) -> Bool {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {

        SocketIOManager.sharedInstance.sendStartTypingMessage(nickname: nickname)
        
        return true
    }

    
    // MARK: UIGestureRecognizerDelegate Methods
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension Notification.Name {
    static let didShowNotification = Notification.Name("handleKeyboardDidShowNotification")
    static let didhidenotification = Notification.Name("handleKeyboardDidHideNotification")
    static let userTypingnotification = Notification.Name("userTypingNotification")
    static let userwasDisconnectnotification = Notification.Name("userWasDisconnectedNotification")
    static let userWasConnectedNotification = Notification.Name("userWasConnectedNotification")

}

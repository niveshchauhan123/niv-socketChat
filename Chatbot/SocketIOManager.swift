//
//  SocketIOManager.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import SocketIO


class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()
    
    
    let manager = SocketManager(socketURL: URL(string: "http://192.168.0.112:3020")!)//"http://localhost:3020")!)
    var date : String!
    
    override init() {
        super.init()
        
        manager.defaultSocket.on(clientEvent: .connect) {data, ack in
            print(data)
        }
    }
    
    
    func addHandlers() {
        manager.defaultSocket.on("ChatMessage") {data, ack in
            print(data)
        }
    }
    
    func establishConnection() {
        manager.connect()
    }
    
    
    func closeConnection() {
        manager.disconnect()
    }
    
    
    
//    func connectToServerWithNickname(nickname: String, completionHandler: (_ userList: [[String: AnyObject]]?) -> Void) {
//
//
//        manager.defaultSocket.on(clientEvent: .connect) {data, ack in
//            print(data)
//            print("socket connected")
//            self.manager.defaultSocket.emit("connectUser", nickname)
//            self.manager.defaultSocket.once("userList", callback: {
//                ( dataArray, ack) -> Void in
//                print(dataArray)
//                completionHandler(dataArray[0] as? [[String: AnyObject]])
//
//            })
//
//            self.manager.defaultSocket.emit(nickname, data)
//        }
//
//
//        listenForOtherMessages()
//    }
    
    func connectToServerWithNickname(nickname: String, completionHandler: @escaping (_ userList: [[String: AnyObject]]?) -> Void) {
        
        self.manager.defaultSocket.emit("connectUser", nickname)
        
        self.manager.defaultSocket.once("userList") { ( dataArray, ack) -> Void in
            
            completionHandler(dataArray[0] as? [[String: AnyObject]])
        }
        
        listenForOtherMessages()
    }
    
    
    func exitChatWithNickname(nickname: String, completionHandler: () -> Void) {
        manager.defaultSocket.emit("exitUser", nickname)
        completionHandler()
    }
    
    
    func sendMessage(msg: String, withNickname nickname: String) {
        manager.defaultSocket.emit("chatMessage", nickname, msg)
    }
    
   
    func getChatMessage(completionHandler: @escaping (_ messageInfo: [String: AnyObject]) -> Void) {
        manager.defaultSocket.on("newChatMessage") { (dataArray, socketAck) -> Void in
            var messageDictionary = [String: AnyObject]()
            messageDictionary["nickname"] = dataArray[0] as! String as AnyObject
            messageDictionary["msg"] = dataArray[1] as! String as AnyObject
            messageDictionary["date"] = dataArray[2] as! String as AnyObject
            
            completionHandler(messageDictionary)
        }
    }
    
    
    private func listenForOtherMessages() {
        manager.defaultSocket.on("userConnectUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: dataArray[0] as! [String: AnyObject])
        }
     
        manager.defaultSocket.on("userExitUpdate") { (dataArray, socketAck) -> Void in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue:"userWasDisconnectedNotification"), object: dataArray[0] as! String)
        }
     
        manager.defaultSocket.on("userTypingUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue:"userTypingNotification"), object: dataArray[0] as! [String: AnyObject])
        }
    }
    
    
    func sendStartTypingMessage(nickname: String) {
        manager.defaultSocket.emit("startType", nickname)
    }
    
    
    func sendStopTypingMessage(nickname: String) {
        manager.defaultSocket.emit("stopType", nickname)
    }
   
}

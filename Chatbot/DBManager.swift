//
//  DBManager.swift
//  Chatbot
//
//  Created by Amit Kaul on 19/07/18.
//  Copyright © 2018 Schoofi. All rights reserved.
//

import UIKit

class DBManager: NSObject {
    
    let field_User_ID = "id"
    let field_User_UserID = "userID"
    let field_User_UserNickname = "nickname"
    let field_User_UserPhoneNumber = "phonenumber"
    let field_User_UserImageURL = "userImageURL"
    let field_User_UserMessage = "message"
    let field_User_MessageDateTime = "dateTime"
    let field_User_SenderID = "senderID"
    let field_User_isRead = "isRead"
    
    static let shared: DBManager = DBManager()
    
    let databaseFileName = "ChatStorage.sqlite"
    
    var pathToDatabase: String!
    
    var database: FMDatabase!
    
    
    override init() {
        super.init()
        
        let documentsDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        pathToDatabase = documentsDirectory.appending("/\(databaseFileName)")
    }
    
    
    
    func createDatabase() -> Bool {
        var created = false
        
        if !FileManager.default.fileExists(atPath: pathToDatabase) {
            database = FMDatabase(path: pathToDatabase!)
            
            if database != nil {
                // Open the database.
                if database.open() {
                    let createChatTableQuery = "create table chat (\(field_User_ID) integer primary key autoincrement, \(field_User_UserID) integer not null, \(field_User_UserNickname) text not null, \(field_User_UserPhoneNumber) integer not null, \(field_User_UserImageURL) text not null, \(field_User_UserMessage) text not null, \(field_User_isRead) bool not null default 0, \(field_User_SenderID) integer not null, \(field_User_MessageDateTime) text not null)"
                    
                    do {
                        try database.executeUpdate(createChatTableQuery, values: nil)
                        created = true
                    }
                    catch {
                        print("Could not create table.")
                        print(error.localizedDescription)
                    }
                    
                    database.close()
                }
                else {
                    print("Could not open the database.")
                }
            }
        }
        
        return created
    }
    
    
    func openDatabase() -> Bool {
        if database == nil {
            if FileManager.default.fileExists(atPath: pathToDatabase) {
                database = FMDatabase(path: pathToDatabase)
            }
        }
        
        if database != nil {
            if database.open() {
                return true
            }
        }
        
        return false
    }
    
    //Save User data in database here...
    func insertUserData(nickname:String, userID: Int, phoneNumber:Int, userImage:String, message:String, isRead:Bool, senderID:Int, dateTime:String) -> Void {
        
        if openDatabase() {
       
              let query = "insert into chat (\(field_User_UserID), \(field_User_UserNickname), \(field_User_UserPhoneNumber), \(field_User_UserImageURL), \(field_User_UserMessage), \(field_User_isRead), \(field_User_SenderID), \(field_User_MessageDateTime)) values (\(userID), '\(nickname)', \(phoneNumber), '\(userImage)', '\(message)', '\(isRead)', \(senderID), '\(dateTime)');"
            
            if !database.executeStatements(query) {
                print("Failed to insert initial data into the database.")
                print(database.lastError(), database.lastErrorMessage())
            }
        }
        
        database.close()

    }
    

    
    /*
    func insertMovieData() {
        if openDatabase() {
            if let pathToMoviesFile = Bundle.main.path(forResource: "movies", ofType: "tsv") {
                do {
                    let moviesFileContents = try String(contentsOfFile: pathToMoviesFile)
                    
                    let moviesData = moviesFileContents.components(separatedBy: "\r\n")
                    
                    var query = ""
                    for movie in moviesData {
                        let movieParts = movie.components(separatedBy: "\t")
                        
                        if movieParts.count == 5 {
                            let movieTitle = movieParts[0]
                            let movieCategory = movieParts[1]
                            let movieYear = movieParts[2]
                            let movieURL = movieParts[3]
                            let movieCoverURL = movieParts[4]
                            
                            query += "insert into movies (\(field_User_ID), \(field_MovieTitle), \(field_MovieCategory), \(field_MovieYear), \(field_MovieURL), \(field_MovieCoverURL), \(field_MovieWatched), \(field_MovieLikes)) values (null, '\(movieTitle)', '\(movieCategory)', \(movieYear), '\(movieURL)', '\(movieCoverURL)', 0, 0);"
                        }
                    }
                    
                    if !database.executeStatements(query) {
                        print("Failed to insert initial data into the database.")
                        print(database.lastError(), database.lastErrorMessage())
                    }
                }
                catch {
                    print(error.localizedDescription)
                }
            }
            
            database.close()
        }
    }
 
    */
    func loadMovies(withId ID: Int) -> [UserChatInfo]! {
        var chats: [UserChatInfo]!
        
        if openDatabase() {
            let query = "select * from chat order by \(field_User_UserID) asc"
            
            do {
                print(database)
                let results = try database.executeQuery(query, values:[ID])
                
                while results.next() {
                    let movie = UserChatInfo(userID: Int(results.int(forColumn: field_User_UserID)),
                                             nickname: results.string(forColumn: field_User_UserNickname),
                                             phoneNumber: Int(results.int(forColumn: field_User_UserPhoneNumber)),
                                             image_URL: results.string(forColumn: field_User_UserImageURL),
                                             msg: results.string(forColumn: field_User_UserMessage),
                                             date: results.string(forColumn: field_User_MessageDateTime),
                                             isRead: Bool(results.bool(forColumn: field_User_isRead)),
                                             sender_ID: Int(results.int(forColumn: field_User_SenderID))
                        
                    )
                    
                    if chats == nil {
                        chats = [UserChatInfo]()
                    }
                    
                    chats.append(movie)
                }
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        
        return chats
    }
 
    /*
    func loadMovie(withID ID: Int, completionHandler: (_ movieInfo: UserChatInfo?) -> Void) {
        var movieInfo: UserChatInfo!
        
        if openDatabase() {
            let query = "select * from chat where \(field_User_UserID)=?"
            
            do {
                let results = try database.executeQuery(query, values: [ID])
                
                if results.next() {
                    movieInfo = UserChatInfo(userID: Int(results.int(forColumn: field_User_UserID)),
                                          nickname: results.string(forColumn: field_User_UserNickname),
                                          phoneNumber: Int(results.int(forColumn: field_User_UserPhoneNumber)),
                                          image_URL: results.string(forColumn: field_User_UserImageURL),
                                          msg: results.string(forColumn: field_User_UserMessage),
                                          date: results.string(forColumn: field_User_MessageDateTime),
                                          isRead: Bool(results.bool(forColumn: field_User_isRead)),
                                          sender_ID: Int(results.int(forColumn: field_User_SenderID))

                    )
                    
                }
                else {
                    print(database.lastError())
                }
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        
        completionHandler(movieInfo)
    }
 
    
    func updateMovie(withID ID: Int, watched: Bool, likes: Int) {
        if openDatabase() {
            let query = "update movies set \(field_MovieWatched)=?, \(field_MovieLikes)=? where \(field_MovieID)=?"
            
            do {
                try database.executeUpdate(query, values: [watched, likes, ID])
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
    }
    
    
    func deleteMovie(withID ID: Int) -> Bool {
        var deleted = false
        
        if openDatabase() {
            let query = "delete from movies where \(field_MovieID)=?"
            
            do {
                try database.executeUpdate(query, values: [ID])
                deleted = true
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        
        return deleted
    }
 */

}

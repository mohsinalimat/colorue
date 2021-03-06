//
//  API.swift
//  Colorue
//
//  Created by Dylan Wight on 4/18/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//

import Foundation
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
//import SinchVerification
import Alamofire

protocol APIDelegate {
    func refresh()
}

class API {
    
    static let sharedInstance = API()

    let myRootRef = FIRDatabase.database().reference()
    
    let storageRef = FIRStorage.storage().reference()
    
    fileprivate var drawingOfTheDay = [Drawing]()
    public var wall = [Drawing]()
    public var explore = [Drawing]()

    fileprivate var facebookFriends = Set<User>()
    fileprivate var contacts = Set<User>()
    fileprivate var popularUsers = Set<User>()
    var hashTags = [HashTag]()

    public var activeUser: User?
    
    fileprivate var oldestTimeLoaded: Double = -99999999999999
    fileprivate var oldestExploreLoaded: Double = -99999999999999
    fileprivate var newestTimeLoaded: Double = 0

    fileprivate lazy var contactStore = ContactStore()
    
    var delegate: APIDelegate?
  
    // MARK: Get Methods
    
    func getActiveUser() -> User {
        return self.activeUser ?? User()
    }
    
    func getDrawingOfTheDay() -> [Drawing] {
        return self.drawingOfTheDay
    }
    
    func getSuggustedUsers() -> [User] {
        return Array(self.popularUsers.union(self.facebookFriends))
    }
    
    func getFriends() -> [User] {
        return Array(facebookFriends.union(contacts))
    }
    
    func getContacts() -> [Contact] {
        return contactStore.getContacts().sorted( by: { $0.name < $1.name } )
    }
    
    //MARK: Load Data
    
    func loadData() {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            let userId = FIRAuth.auth()!.currentUser!.uid
            UserService().get(userId: userId, callback: { (activeUser: User) -> () in
                self.activeUser = activeUser
                UserService().getFull(user: activeUser)
                self.loadDrawingOfTheDay()
                self.loadWall()
                self.setDeleteWall()
                self.loadExplore()
                self.setDeleteExplore()
                self.loadFacebookFriends()
                self.loadHashTags()
                self.delegate?.refresh()
            })
        })
    }
    
    func clearData() {
        self.facebookFriends.removeAll()
        self.wall.removeAll()
        self.activeUser = nil
        self.oldestExploreLoaded = -99999999999999
        self.oldestTimeLoaded = -99999999999999
        self.newestTimeLoaded = 0
    }

    // Used both for initial load and to add older drawings
    func loadWall() {
        guard let activeUser = activeUser else { return }

        myRootRef.child("users/\(activeUser.userId)/wall").queryOrderedByValue().queryLimited(toFirst: 16).queryStarting(atValue: self.oldestTimeLoaded)
            .observe(.childAdded, with: { snapshot in
                DrawingService().get(id: snapshot.key, callback: { (drawing: Drawing, new: Bool) -> () in
                    if self.wall.count == 0 {
                        self.wall.append(drawing)
                        self.oldestTimeLoaded = drawing.timeStamp
                        self.newestTimeLoaded = drawing.timeStamp
                    } else if drawing.timeStamp > self.oldestTimeLoaded {
                        self.oldestTimeLoaded = drawing.timeStamp
                        self.wall.append(drawing)
                    } else if drawing.timeStamp < self.newestTimeLoaded {
                        self.newestTimeLoaded = drawing.timeStamp
                        self.wall.insert(drawing, at: 0)
                    } else {
                        if new {
                            var i = 0
                            for drawing_ in self.wall {
                                if drawing_.timeStamp > drawing.timeStamp {
                                    self.wall.insert(drawing, at: i)
                                    return
                                }
                                i += 1
                            }
                        }
                    }
                })
            })
    }
    
    fileprivate func setDeleteWall() {
        guard let activeUser = activeUser else { return }

        myRootRef.child("users/\(activeUser.userId)/wall").observe(.childRemoved, with: { snapshot in
                let drawingId = snapshot.key
                var i = 0
                for drawing in self.wall {
                    if drawing.id == drawingId {
                        self.wall.remove(at: i)
                        return
                    }
                    i += 1
                }
            })
        }
    
    func loadExplore() {
        myRootRef.child("drawings").queryOrdered(byChild: "timeStamp").queryLimited(toFirst: 8)
            .queryStarting(atValue: self.oldestExploreLoaded).observe(.childAdded, with: { snapshot in
                let drawingId = snapshot.key
                DrawingService().get(id: drawingId, callback: { (drawing: Drawing, new: Bool) -> () in
                    self.oldestExploreLoaded = drawing.timeStamp + 1
                    self.explore.append(drawing)
                })
            })
    }
    
    private func setDeleteExplore() {
        myRootRef.child("drawings").observe(.childRemoved, with: { snapshot in
            let drawingId = snapshot.key
            var i = 0
            for drawing in self.explore {
                if drawing.id == drawingId {
                    self.explore.remove(at: i)
                    return
                }
                i += 1
            }
        })
    }
    
    func loadDrawingOfTheDay() {
        myRootRef.child("drawingOfTheDay").observe(.value, with: { snapshot in
            guard snapshot.exists() else { return }
            DrawingService().get(id: snapshot.value as! String, callback: { (drawing: Drawing, new: Bool) -> () in
                self.drawingOfTheDay.removeAll()
                self.drawingOfTheDay.append(drawing)
                DispatchQueue.main.async {
                    self.delegate?.refresh()
                }
            })
        })
    }
    
    func loadHashTags() {
        myRootRef.child("hashTags").queryOrderedByValue().queryLimited(toFirst: 8)
            .observe(.childAdded, with: { snapshot in
                guard snapshot.exists() else { return }
                HashTagService().get(tag:  snapshot.key, callback: { hashTag in
                    self.hashTags.append(hashTag)
                })
            })
    }
    
    func loadFacebookFriends() {
        let request = FBSDKGraphRequest(graphPath: "/me/friends", parameters: ["fields": "friends"], httpMethod: "GET")
        
        request?.start(completionHandler: { (connection, result, error) -> Void in
            
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                let resultdict = result as! NSDictionary
                let data : NSArray = resultdict.object(forKey: "data") as! NSArray
                for i in 0 ..< data.count {
                    let valueDict : NSDictionary = data[i] as! NSDictionary
                    let id = valueDict.object(forKey: "id") as! String
                    self.loadUserByFBID(id)
                }
            }
        })
    }
    
    fileprivate func loadUserByFBID(_ FBID: String) {
        myRootRef.child("userLookup/FacebookIDs/\(FBID)").observe(.value, with: { snapshot in
            if !snapshot.exists() { return }
            let userID = snapshot.value as! String
            UserService().get(userId: userID, callback: { (user: User) -> () in
                self.facebookFriends.insert(user)
            })
        })
    }
    
    func removeFBFriend(_ user: User) {
        self.facebookFriends.remove(user)
    }
    
    func loadPopularUsers() {
        myRootRef.child("popularUsers").observe(.childAdded, with: { snapshot in
            guard snapshot.exists() else { return }
            let userID = snapshot.key
            UserService().get(userId: userID, callback: { (user: User) -> () in
                self.popularUsers.insert(user)
            })
        })
    }
    
    func checkNumber(_ number: String) {

        myRootRef.child("userLookup/phoneNumbers/\(number)").observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else { return }
            
            let userID = snapshot.value as! String
            UserService().get(userId: userID, callback: { (user: User) -> () in
                self.contacts.insert(user)
                self.delegate?.refresh()
            })
        })
    }

    // MARK: Image Upload + Download Methods
    
    func uploadImage(_ drawing: Drawing, progressCallback: @escaping (Float) -> (), finishedCallback: @escaping (Bool) -> ()) {
        
        let uploadTask = storageRef.child("drawings/\(drawing.id).png").put(UIImagePNGRepresentation(drawing.image)!)
        
        uploadTask.observe(.progress) { snapshot in
            // Upload reported progress
            if let progress = snapshot.progress {
                let percentComplete = Float(100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount))
                progressCallback(percentComplete)
            }
        }
        
        uploadTask.observe(.success) { snapshot in
            progressCallback(1.0)
            finishedCallback(true)
        }
        
        uploadTask.observe(.failure) { snapshot in
            finishedCallback(false)
        }
    }
    
    func setDrawingURL(_ drawingId: String, callback: @escaping ((URL?)->())) {
        let drawingRef = storageRef.child("drawings/\(drawingId).png")
        
        drawingRef.downloadURL { (URL, error) -> Void in
            guard error == nil else { return }
            self.myRootRef.child("drawings/\(drawingId)/url").setValue(URL?.absoluteString)
            callback(URL)
        }
    }
}

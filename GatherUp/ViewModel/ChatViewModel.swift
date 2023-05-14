//
//  ChatViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/18.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class ChatViewModel: FirebaseViewModelwithMeetings {

    @Published var messages: [ChatMessage] = []
    @Published  var lastMessageId: String = ""
    
    ///채팅구현
    func messagesListener(meetingID: String) {
        isLoading = true
        Task{
            let listener = db.collection(strMeetings).document(meetingID).collection(strMessage)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {print("에러!messagesListener:\(error)");return}
                guard let documents = querySnapshot?.documents else {return}
                
                self.messages = documents.compactMap { document -> ChatMessage? in
                    let data = document.data()
                    let id = document.documentID
                    let text = data["text"] as? String ?? ""
                    let userId = data["userUID"] as? String ?? ""
                    let userName = data["userName"] as? String ?? ""
                    let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
                    let isSystemMessage = data["isSystemMessage"] as? Bool ?? false
                    
                    return ChatMessage(id: id, text: text, userUID: userId, timestamp: timestamp ,isSystemMessage:isSystemMessage)
                }
            }
            listeners.append(listener)
            isLoading = false
        }
    }
    
    func sendMessage(meetingID: String, text: String) {
        isLoading = true
        Task{
            do{
                await fetchCurrentUserAsync()
                try await db.collection(strMeetings).document(meetingID).collection(strMessage).addDocument(data: [
                    "text": text,
                    "userUID": currentUID as Any,
                    "timestamp": Timestamp()
                ])
                isLoading = false
            }catch{
                await handleError(error)
            }
        }
    }
    
    func joinChat(meetingID: String, userName: String) {
        let joinMessage = "\(userName)님이 채팅에 참가하셨습니다."
        sendSystemMessage(meetingID: meetingID, text: joinMessage)
    }
    
    func sendSystemMessage(meetingID: String, text: String) {
        db.collection(strMeetings).document(meetingID).collection(strMessage).addDocument(data: Message.systemMessage(text))
    }

    
    func getMessage(){
        if let id = self.messages.last?.id {
            self.lastMessageId = id
        }
    }
}
/*
func sendDM(message: String, senderID: String, receiverID: String, senderName: String, receiverName: String) {
    let db = Firestore.firestore()
    
    let messageData: [String: Any] = [
        "message": message,
        "senderID": senderID,
        "receiverID": receiverID,
        "senderName": senderName,
        "receiverName": receiverName,
        "timestamp": Timestamp(date: Date()),
        "participants": [senderID, receiverID]
    ]
    
    let peopleData: [String: [String]] = [
        "users": [senderID,receiverID]
    ]
//    struct DMPeople: Identifiable,Codable,Equatable, Hashable{
//        var id: String?
//
//        var users: [String]
//    }
//    struct Chatter: Identifiable,Codable,Equatable, Hashable{
//        var id: String?
//
//        var chatterUID: String
//        var DMPeopleID: String
//    }
    
    let users: DMPeople = DMPeople(users: [senderID,receiverID])
    
    let doc = db.collection("Users").document(senderID).collection("Chatters")
    
    let dmPeopleDoc = db.collection("DMPeople").whereField("users", arrayContains: senderID)
    
    dmPeopleDoc.getDocuments{ querySnapshot, err in
        
    }
    
    
    doc.whereField("chatterUID", isEqualTo: receiverID).getDocuments{ querySnapshot, err in
        if let err = err {
            print("Error getting documents: \(err)")
        } else {
            
            if querySnapshot!.documents.isEmpty {
                
                dmPeopleDoc.getDocuments{ querySnapshot, err in
                    guard let documents = querySnapshot?.documents else{return}
                    var dmPeopleID: String?
                    for document in documents {
                        let usersUID = document.data()["users"] as? [String] ?? []
                        for userUID in usersUID {
                            if userUID == receiverID {
                                dmPeopleID = document.documentID
                            }
                        }
                    }
                    var documentID: String?
                    if let dmPeopleID {
                        db.collection("DMPeople").document(dmPeopleID).collection("DM").addDocument(data: messageData)
                    } else {
                        let documentRef = try? db.collection("DMPeople").addDocument(from: users)
                        guard let documentRef = documentRef else{return}
                        documentID = documentRef.documentID
                        let chatter = Chatter(chatterUID: receiverID, DMPeopleID: documentID!)
                        try? doc.addDocument(from: chatter){ _ in
                            db.collection("DMPeople").document(documentID!).collection("DM").addDocument(data: messageData)
                        }
                    }
                    let receiverDoc = db.collection("Users").document(receiverID).collection("Chatters")
                    
                    receiverDoc.whereField("chatterUID", isEqualTo: senderID).getDocuments{ querySnapshot, err in
                        if querySnapshot!.documents.isEmpty {
                            guard let documentID = documentID else{return}
                            let chatter = Chatter(chatterUID: senderID, DMPeopleID: documentID)
                            try? receiverDoc.addDocument(from: chatter)
                        }
                    }
                }
            }
        }
    }
}
    
*/

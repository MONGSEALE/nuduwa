//
//  ChatViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/18.
//

import SwiftUI
import Firebase
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    //chat기능 변수
    private let db = Firestore.firestore()
    private let strMeetings = "Meetings"        // Firestore에 저장된 콜렉션 이름
    private let strMembers = "Members"          // Firestore에 저장된 콜렉션 이름
    private let strMessage = "Message"          // Firestore에 저장된 콜렉션 이름
    
    
    private var docListener: ListenerRegistration?
    @Published var messages: [ChatMessage] = []
    @Published  var lastMessageId: String = ""
    
    
    
    
    ///채팅구현
    func messagesListener(meetingId: String) {
        docListener = db.collection(strMeetings).document(meetingId).collection(strMessage)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {print("에러!messagesListner:\(error)");return}
                guard let documents = querySnapshot?.documents else {return}
                
                
                self.messages = documents.compactMap { queryDocumentSnapshot -> ChatMessage? in
                    let data = queryDocumentSnapshot.data()
                    let id = queryDocumentSnapshot.documentID
                    let text = data["text"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let userName = data["userName"] as? String ?? ""
                    let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
                    let isSystemMessage = data["isSystemMessage"] as? Bool ?? false
                    
                    return ChatMessage(id: id, text: text, userUID: userId, userName: userName, timestamp: timestamp ,isSystemMessage:isSystemMessage)
                }
            }
    }
    
    func sendMessage(meetingId: String, text: String) {
        let user = Auth.auth().currentUser
        db.collection(strMeetings).document(meetingId).collection(strMessage).addDocument(data: [
            "text": text,
            "userId": user?.uid as Any,
            "userName": user?.displayName as Any,
            "timestamp": Timestamp()
        ])
    }
    
    func joinChat(meetingId: String, userName: String) {
        let joinMessage = "\(userName)님이 채팅에 참가하셨습니다."
        sendSystemMessage(meetingId: meetingId, text: joinMessage)
    }
    
    func sendSystemMessage(meetingId: String, text: String) {
        db.collection(strMeetings).document(meetingId).collection(strMessage).addDocument(data: [
            "text": text,
            "userId": "SYSTEM",
            "userName": "SYSTEM",
            "timestamp": Timestamp(),
            "isSystemMessage": true
        ])
    }

    
    func getMessage(){
        if let id = self.messages.last?.id {
            self.lastMessageId = id
        }
    }
}


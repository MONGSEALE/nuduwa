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

    func getMembersData(){
        Task{
            for uid in dicMembers.keys{
                do {
                    let document = try await db.collection(strUsers).document(uid).getDocument()
                    let name = document.data()?["userName"] as? String ?? ""
                    let imageUrl = document.data()?["userImage"] as? String ?? ""
                    let image = URL(string: imageUrl)
                    self.dicMembersData[uid] = MemberData(memberName: name, memberImage: image!)
                } catch {
                    print("Error getting document: \(error)")
                }
            }
            
        }
    }
    ///채팅구현
    func messagesListener(meetingID: String) {
        isLoading = true
        Task{
            docListener = db.collection(strMeetings).document(meetingID).collection(strMessage)
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
            await MainActor.run(body: {
                isLoading = false
            })
            
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
        db.collection(strMeetings).document(meetingID).collection(strMessage).addDocument(data: [
            "text": text,
            "userUID": "SYSTEM",
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


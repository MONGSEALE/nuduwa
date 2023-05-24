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

    @Published var messages: [Message] = []
    @Published var lastMessageId: String = ""
    @Published var nonMembers: [String: Member] = [:]  // Message 치고 나간 사람 배열
    
    func fetchNonMembers() {
        for message in messages {
            if !members.contains(where: {$0.memberUID == message.senderUID}){
                Task{
                    let memberData = try await getUserData(message.senderUID)
                    await MainActor.run{
                        self.nonMembers[message.senderUID] = Member(memberUID: memberData.id!, memberName: memberData.userName, memberImage: memberData.userImage)
                    }
                }
            }
        }
        
    }
    ///채팅구현
    func messagesListener(meetingID: String) {
        isLoading = true
        Task{
            let query = db.collection(strMeetings).document(meetingID).collection(strMessage)
            .order(by: "timestamp", descending: false)
            let listener = query.addSnapshotListener { querySnapshot, error in
                if let error = error {print("에러!messagesListener:\(error)");return}
                guard let documents = querySnapshot?.documents else {return}
                
                self.messages = documents.compactMap { document -> Message? in
                    document.data(as: Message.self)
                }
                
                self.fetchNonMembers()
            }
            listeners[query.description] = listener
            await MainActor.run{
                isLoading = false
            }
        }
    }
    
    func sendMessage(meetingID: String, text: String) {
        isLoading = true
        Task{
            do{
                guard let currentUID = currentUID else{return}
                let message = Message(text, uid: currentUID)
                let col = db.collection(strMeetings).document(meetingID).collection(strMessage)
                try await col.addDocument(data: message.firestoreData)
                // try await col.addDocument(data: [
                //     "text": text,
                //     "userUID": currentUID as Any,
                //     "timestamp": Timestamp()
                // ])
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
        let col = db.collection(strMeetings).document(meetingID).collection(strMessage)
        let message = Message.createSystemMessage(text)
        col.addDocument(data: message.firestoreData)
    }

    
    func getMessage(){
        if let id = self.messages.last?.id {
            self.lastMessageId = id
        }
    }
}

//
//  DMViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import Foundation
import Combine
import Firebase
import FirebaseFirestore

class DMViewModel: FirebaseViewModel {
    
    @Published var messages: [DM] = []
    @Published var chattingRooms: [Chatter] = []
    @Published var isTabBarHidden: Bool = false
    @Published var userImageURLs: [String: User] = [:]
    @State var unreadMessages : Int = 1
   
    
    


    func sendDM(message: String, receiverID: String) {
        guard let senderID = Auth.auth().currentUser?.uid else { return }
        if message.isEmpty { return }
        
        let messageData: [String: Any] = [
            "message": message,
            "senderID": senderID,
            "receiverID": receiverID,
            "timestamp": Timestamp(date: Date()),
            "participants": [senderID, receiverID]
        ]
        
        let users = DMPeople(users: [senderID,receiverID])
        let doc = self.db.collection("Users").document(senderID).collection("Chatters")
        
        self.db.collection("DMPeople").whereField("users", in: [[senderID, receiverID], [receiverID, senderID]]).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else if let document = querySnapshot?.documents.first {
                let documentID = document.documentID
                self.db.collection("DMPeople").document(documentID).collection("DM").addDocument(data: messageData)
                
                doc.whereField("chatterUID", isEqualTo: receiverID).getDocuments { querySnapshot, err in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else if querySnapshot!.documents.isEmpty {
                        let chatter = Chatter(chatterUID: receiverID, DMPeopleID: documentID, unreadMessages: 1)
                        try? doc.addDocument(from: chatter)
                    }
                }
                
                let receiverDoc = self.db.collection("Users").document(receiverID).collection("Chatters")
                receiverDoc.whereField("chatterUID", isEqualTo: senderID).getDocuments { querySnapshot, err in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else if querySnapshot!.documents.isEmpty {
                        let chatter = Chatter(chatterUID: senderID, DMPeopleID: documentID, unreadMessages: 1)
                        try? receiverDoc.addDocument(from: chatter)
                    } else {
                        // If Chatter document exists, increment the unreadMessages field
                        if let chatRoomID = querySnapshot?.documents.first?.documentID {
                                self.incrementUnreadMessages(receiverID: receiverID, chatRoomID: chatRoomID)
                        }
                    }
                }
                
            } else {
                do {
                    let documentRef = try self.db.collection("DMPeople").addDocument(from: users)
                    let documentID = documentRef.documentID
                    let chatter = Chatter(chatterUID: receiverID, DMPeopleID: documentID, unreadMessages: 1)
                    try doc.addDocument(from: chatter) { _ in
                        self.db.collection("DMPeople").document(documentID).collection("DM").addDocument(data: messageData)
                    }
                    let receiverDoc = self.db.collection("Users").document(receiverID).collection("Chatters")
                    let chatter2 = Chatter(chatterUID: senderID, DMPeopleID: documentID, unreadMessages: 1)
                    try? receiverDoc.addDocument(from: chatter2)
                } catch let error {
                    print("Error writing DMPeople document: \(error)")
                }
            }
        }
    }

    
    func receiverUser(id: String) {
       if let _ = userImageURLs[id] {
           // Image URL already fetched, do nothing
           return
       } else {
           let userDocumentRef = Firestore.firestore().collection("Users").document(id)
           userDocumentRef.getDocument { documentSnapshot, error in
               if let error = error {
                   print("Error retrieving user profile image URL: \(error.localizedDescription)")
               } else if let documentSnapshot = documentSnapshot, let data = documentSnapshot.data() {
                   if let user = try? documentSnapshot.data(as: User.self) {
                       DispatchQueue.main.async {
                           self.userImageURLs[id] = user
                       }
                   }
               }
           }
       }
   }
    
    func startListeningDM(senderID: String, receiverID: String) {
        print("startListeningDM")
        let doc = Firestore.firestore().collection(strUsers).document(senderID).collection(strChatters)
        var dmPeopleID: String?
        
        doc.whereField("chatterUID", isEqualTo: receiverID).getDocuments{ querySnapshot, error in
            if let querySnapshot = querySnapshot {
                for document in querySnapshot.documents {
                    dmPeopleID = document.data()["DMPeopleID"] as? String ?? ""
                }
                
                guard let dmPeopleID = dmPeopleID else{print("디엠피플오류");return}
                print("dmPeopleID:\(dmPeopleID)")
                // 두 유저 간의 DM 문서를 참조합니다.
                let dmDocumentRef = Firestore.firestore().collection(self.strDMPeople).document(dmPeopleID)

                // DM 문서 내의 DM 컬렉션을 참조합니다.
                let dmCollectionRef = dmDocumentRef.collection(self.strDM)

                // DM 컬렉션에서 모든 DM을 시간순으로 가져오는 쿼리를 생성합니다.
                let query = dmCollectionRef.order(by: "timestamp")
                
                // 쿼리의 결과에 대한 리스너를 추가합니다.
                self.docListener = query.addSnapshotListener { querySnapshot, error in
                    print("dm리스너")
                    if let querySnapshot = querySnapshot {
                        // 쿼리 결과를 DM 객체의 배열로 변환하고, 이를 messages 배열에 저장합니다.
                        self.messages = querySnapshot.documents.compactMap { document -> DM? in
                            try? document.data(as: DM.self)
                        }
                        print("메시지:\(self.messages)")
                    } else if let error = error {
                        print("Error listening for DMs: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        

                    

                    // 채팅방 ID를 얻습니다. 이는 ChatRoomID를 가져오는 별도의 메서드를 통해 얻을 수 있습니다.
                    self.fetchChatRoomID(receiverID: receiverID) { chatRoomID in
                        // 새로운 메시지가 도착하면 unreadMessages를 0으로 설정
                        self.resetUnreadMessages(userID: senderID, chatRoomID: chatRoomID)
                    }
                }
    
    
    func startListeningRecentMessages() {
        guard let currentUID = currentUID else{return}
        isLoading = true
        print("startListeningRecentMessages,uid:\(currentUID)")
        
        let chatterDoc = db.collection(strUsers).document(currentUID).collection(strChatters)
        
        chatterDoc.addSnapshotListener{ querySnapshot, error in
            if let error = error {
                print("Error listening for DM updates: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("mapMeetingsListener 에러1: \(String(describing: error))")
                self.isLoading = false
                return
            }
            print("documents:\(documents)")
            self.chattingRooms = documents.compactMap{ documents -> Chatter? in
                try? documents.data(as: Chatter.self)
            }
            self.isLoading = false
            print("Rooms:\(self.chattingRooms)")
        }

    }

    func uniqueChatDocumentID(senderID: String, receiverID: String) -> String {
        return senderID < receiverID ? "\(senderID)_\(receiverID)" : "\(receiverID)_\(senderID)"
    }
    
    func leaveChatroom(chatroom: Chatter) {
          guard let currentUID = currentUID else { return }
          let docRef = db.collection(strUsers).document(currentUID).collection(strChatters).document(chatroom.id ?? "")
          docRef.delete() { err in
              if let err = err {
                  print("Error removing document: \(err)")
              } else {
                  print("Document successfully removed!")
              }
          }
      }
    
    func incrementUnreadMessages(receiverID: String, chatRoomID: String) {
        let docRef = self.db.collection("Users").document(receiverID).collection("Chatters").document(chatRoomID)
       
        docRef.updateData([
            "unreadMessages": FieldValue.increment(Int64(1))
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
                print("성공적으로 됬당께")
            }
        }
    }
    
    func resetUnreadMessages(userID: String, chatRoomID: String) {
        let docRef = Firestore.firestore().collection("Users").document(userID).collection("Chatters").document(chatRoomID)

        docRef.updateData([
            "unreadMessages": 0
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func fetchChatRoomID(receiverID: String, completion: @escaping (String) -> Void) {
        let userUID = Auth.auth().currentUser?.uid ?? ""
        db.collection("Users").document(userUID).collection("Chatters").whereField("chatterUID", isEqualTo: receiverID).getDocuments { (snapshot, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            if let document = snapshot?.documents.first {
                completion(document.documentID)
            }
        }
    }

}



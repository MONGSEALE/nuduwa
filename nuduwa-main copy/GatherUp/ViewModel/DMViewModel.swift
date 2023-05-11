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
    
    func sendDM(message: String, receiverID: String) {
        
        guard let senderID = currentUID else{return}
        if message == "" {return}

        let messageData: [String: Any] = [
            "message": message,
            "senderID": senderID,
            "receiverID": receiverID,
            "timestamp": Timestamp(date: Date()),
            "participants": [senderID, receiverID]
        ]

        let users: DMPeople = DMPeople(users: [senderID,receiverID])

        let doc = db.collection(strUsers).document(senderID).collection(strChatters)
            
        doc.whereField("chatterUID", isEqualTo: receiverID).getDocuments{ querySnapshot, err in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if querySnapshot!.documents.isEmpty {
                    let documentRef = try? self.db.collection(self.strDMPeople).addDocument(from: users)
                    guard let documentRef = documentRef else{return}
                    let documentID = documentRef.documentID
                    let chatter = Chatter(chatterUID: receiverID, DMPeopleID: documentID)
                    try? doc.addDocument(from: chatter){ _ in
                        self.db.collection(self.strDMPeople).document(documentID).collection(self.strDM).addDocument(data: messageData)
                    }
                    let receiverDoc = self.db.collection(self.strUsers).document(receiverID).collection(self.strChatters)
                    
                    receiverDoc.whereField("chatterUID", isEqualTo: senderID).getDocuments{ querySnapshot, err in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            if querySnapshot!.documents.isEmpty {
                                let chatter = Chatter(chatterUID: senderID, DMPeopleID: documentID)
                                try? receiverDoc.addDocument(from: chatter)
                            }
                        }
                    }
                } else {
                    for document in querySnapshot!.documents {
                        let documentID = document.get("DMPeopleID") as! String
                        try? self.db.collection(self.strDMPeople).document(documentID).collection(self.strDM).addDocument(data: messageData)
                    }
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
//        docListener = db.collection(strDMPeople)
//            .order(by: "timestamp", descending: true)
//            .addSnapshotListener { querySnapshot, error in
//                if let error = error {
//                    print("Error listening for DM updates: \(error.localizedDescription)")
//                    return
//                }
//                querySnapshot?.documents.forEach { document in
//                    if let dm = try? document.data(as: DM.self) {
//                        let receiverID = dm.senderID == Auth.auth().currentUser?.uid ? dm.receiverID : dm.senderID
//
//                        if let currentRecentMessage = self.recentMessages[receiverID], currentRecentMessage.timestamp.dateValue() >= dm.timestamp.dateValue() {
//                            return
//                        }
//
//                        self.recentMessages[receiverID] = dm
//                    }
//                }
//            }
    }

    func uniqueChatDocumentID(senderID: String, receiverID: String) -> String {
        return senderID < receiverID ? "\(senderID)_\(receiverID)" : "\(receiverID)_\(senderID)"
    }
    
//    func deleteRecentMessage(receiverID: String) {
//        let docListener = Firestore.firestore().collection("Users").document(currentUID).collection("recentMessages")
//        docListener.document(receiverID).delete { [weak self] error in
//            if let error = error {
//                print("Error deleting recent message: \(error.localizedDescription)")
//            } else {
//                DispatchQueue.main.async {
//                    self?.recentMessages.removeValue(forKey: receiverID)
//                    print("Recent message successfully deleted")
//                }
//            }
//        }
//    }
}


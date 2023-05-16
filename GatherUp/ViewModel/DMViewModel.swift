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
    
    @Published var messages: [Message] = []
    @Published var chattingRooms: [DMList] = []
    @Published var isTabBarHidden: Bool = false
    @Published var userImageURLs: [String: User] = [:]
    
    func sendDM(message: String, receiverID: String) {
        if message == "" {return}
        Task{
            do{
                guard let senderID = currentUID else{return}
                let dmPeople = DMPeople(chattersUID: [senderID,receiverID])
                let dmListcol = db.collection(strUsers).document(senderID).collection(strChatters)
                let dmPeoplecol = db.collection(strDMPeople)
                
                let messageData = Message(message, uid: senderID)
                
                let dmListSnapshot = try await dmListcol.whereField("chatterUID", isEqualTo: receiverID).getDocuments()
                
                if dmListSnapshot.documents.isEmpty {
                    var documentRef: DocumentReference?
                    let dmPeopleSnapshot = try await dmPeoplecol.whereField("chattersUID", arrayContains: receiverID).getDocuments()
                    if dmPeopleSnapshot.documents.isEmpty {
                        documentRef = try await dmPeoplecol.addDocument(data: dmPeople.firestoreData)
                    } else {
                        dmPeopleSnapshot.documents.forEach{ document in
                            documentRef = document.reference
                        }
                    }
                    guard let documentRef = documentRef else{return}
                    
                    let documentID = documentRef.documentID
                    let chatter = DMList(chatterUID: receiverID, DMPeopleID: documentID)
                    
                    try await dmListcol.addDocument(data: chatter.firestoreData)
                    
                    try await dmPeoplecol.document(documentID).collection(strDM).addDocument(data: messageData.firestoreData)
                    
                    let receiverDoc = self.db.collection(self.strUsers).document(receiverID).collection(self.strChatters)
                } else {
                    for document in dmListSnapshot.documents {
                        let documentID = document.get("DMPeopleID") as! String
                        try await dmPeoplecol.document(documentID).collection(self.strDM).addDocument(data: messageData.firestoreData)
                    }
                }
            }catch{
                print("오류!sendDM")
            }
            
        }
    }
    
    func startListeningDM(chatterUID: String) {
        print("startListeningDM")
        Task{
            guard let currentUID = currentUID else{return}
            let chattersQuery = db.collection(strUsers).document(currentUID).collection(strChatters)
                .whereField("chatterUID", isEqualTo: chatterUID)
            let dmPeopleDoc = db.collection(strDMPeople)
            let dmPeopleQuery = dmPeopleDoc.whereField("users", arrayContains: chatterUID)
            var dmPeopleID: String?
            
            do{
                let chattersSnapshot = try await chattersQuery.getDocuments()
                
                if !chattersSnapshot.documents.isEmpty {
                    for document in chattersSnapshot.documents {
                        dmPeopleID = document.data()["DMPeopleID"] as? String ?? ""
                    }
                } else {
                    let dmPeopleSnapshot = try await dmPeopleQuery.getDocuments()
                    
                    if !dmPeopleSnapshot.documents.isEmpty {
                        for document in dmPeopleSnapshot.documents {
                            dmPeopleID = document.documentID
                        }
                    } else {
                        print("서버저장된DM없음")
                        return
                    }
                }
                
                guard let dmPeopleID = dmPeopleID else {return}
                
                let dmDoc = dmPeopleDoc.document(dmPeopleID).collection(self.strDM)
                let query = dmDoc.order(by: "timestamp")
                
                let listener = query.addSnapshotListener { querySnapshot, error in
                    if let error = error {self.handleErrorTask(error);return}
                    guard let querySnapshot = querySnapshot else {return}
                    
                    self.messages = querySnapshot.documents.compactMap { document -> Message? in
                        try? document.data(as: Message.self)
                    }
                }
                listeners[query.description] = listener
            } catch {
                handleErrorTask(error)
            }
        }
    }
    
    func dmListener(dmPeopleID: String) {
        print("dmListener")
        guard let currentUID = currentUID else{return}
        let query = db.collection(strDMPeople).document(dmPeopleID).collection(strDM)
                    .order(by: "timestamp")

        let listener = query.addSnapshotListener { querySnapshot, error in
                        if let error = error {self.handleErrorTask(error);return}
                        guard let querySnapshot = querySnapshot else{return}
                        // 쿼리 결과를 DM 객체의 배열로 변환하고, 이를 messages 배열에 저장합니다.
                        self.messages = querySnapshot.documents.compactMap { document -> Message? in
                            try? document.data(as: Message.self)
                        }
                    }
        listeners[query.description] = listener
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
            self.chattingRooms = documents.compactMap{ documents -> DMList? in
                try? documents.data(as: DMList.self)
            }
            self.isLoading = false
            print("Rooms:\(self.chattingRooms)")
        }
    }

    func uniqueChatDocumentID(senderID: String, receiverID: String) -> String {
        return senderID < receiverID ? "\(senderID)_\(receiverID)" : "\(receiverID)_\(senderID)"
    }
    
    func deleteRecentMessage(receiverID: String) {
//        isLoading = true
        guard let currentUID = currentUID else{return}
        let query = db.collection(strUsers).document(currentUID).collection(strChatters)
            .whereField("chatterUID", isEqualTo: receiverID)
        query.getDocuments{ querySnapshot, error in
            if let error = error {
                return
            } else {
                guard let documents = querySnapshot?.documents else {
                    
                    return
                }

                for document in documents {
                    document.reference.delete(){ error in
                        guard let error = error else{
                            return
                        }
                        print("DM나가기 완료")
                        self.isLoading = false
                        
                    }
                }
            }
        }
    }
}


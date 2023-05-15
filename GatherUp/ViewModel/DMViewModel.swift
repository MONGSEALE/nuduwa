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
        
        guard let senderID = currentUID else{return}
        if message == "" {return}

        let messageData: [String: Any] = [
            "message": message,
            "senderID": senderID,
            "receiverID": receiverID,
            "timestamp": Timestamp(date: Date()),
            "participants": [senderID, receiverID]
        ]

        let users: DMPeople = DMPeople(chattersUID: [senderID,receiverID])

        let doc = db.collection(strUsers).document(senderID).collection(strChatters)
            
        doc.whereField("chatterUID", isEqualTo: receiverID).getDocuments{ querySnapshot, err in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if querySnapshot!.documents.isEmpty {
                    let documentRef = try? self.db.collection(self.strDMPeople).addDocument(from: users)
                    guard let documentRef = documentRef else{return}
                    let documentID = documentRef.documentID
                    let chatter = DMList(chatterUID: receiverID, DMPeopleID: documentID)
                    try? doc.addDocument(from: chatter){ _ in
                        self.db.collection(self.strDMPeople).document(documentID).collection(self.strDM).addDocument(data: messageData)
                    }
                    let receiverDoc = self.db.collection(self.strUsers).document(receiverID).collection(self.strChatters)
                    
                    receiverDoc.whereField("chatterUID", isEqualTo: senderID).getDocuments{ querySnapshot, err in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            if querySnapshot!.documents.isEmpty {
                                let chatter = DMList(chatterUID: senderID, DMPeopleID: documentID)
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
        /*
        chattersQuery.getDocuments{ querySnapshot, error in
            if let error = error || querySnapshot == nil {self.handleErrorTask(error);return}

            if !querySnapshot.documents.isEmpty {
                for document in querySnapshot.documents {
                    dmPeopleID = document.data()["DMPeopleID"] as? String ?? ""
                }
            } else {
                dmPeopleQuery.getDocuments{ querySnapshot, error in
                    if let error = error || querySnapshot == nil {self.handleErrorTask(error);return}

                    if !querySnapshot.documents.isEmpty {
                        for document in querySnapshot.documents {
                            dmPeopleID = document.documentID
                        }
                    } else {
                        print("서버저장된DM없음");return
                    }
                }
            }
            guard let dmPeopleID = dmPeopleID else{print("디엠피플오류");return}
            print("dmPeopleID:\(dmPeopleID)")
            // 두 유저 간의 DM 문서를 참조합니다.
            let dmDoc = dmPeopleDoc.document(dmPeopleID).collection(self.strDM)

            // DM 컬렉션에서 모든 DM을 시간순으로 가져오는 쿼리를 생성합니다.
            let query = dmDoc.order(by: "timestamp")
            
            // 쿼리의 결과에 대한 리스너를 추가합니다.
            self.docListener = query.addSnapshotListener { querySnapshot, error in
                if let error = error || querySnapshot == nil {self.handleErrorTask(error);return}
                    // 쿼리 결과를 DM 객체의 배열로 변환하고, 이를 messages 배열에 저장합니다.
                self.messages = querySnapshot.documents.compactMap { document -> DM? in
                    try? document.data(as: DM.self)
                }
            }
        }*/
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


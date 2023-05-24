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
    
    @Published var messages: [Message] = []             // 메시지 배열 - 채팅방에서 사용
    @Published var chattingRooms: [DMList] = []         // DMList 배열 - 채팅방리스트에서 사용

    @Published var dmPeopleRef: DocumentReference? = nil            // Firestore 메시지 저장될 경로
    var currentDMListDocRef: DocumentReference? = nil   // Firestore 사용자 DMList 경로
    var receiverDMListDocRef: DocumentReference? = nil  // Firestore 상대방 DMList 경로
    var paginationDoc: QueryDocumentSnapshot? = nil     // Firestore 문서 가져올때 페이지변수
    
    var isReading: Bool = false                         // 채팅방 들어갔는지 확인변수
    
    
    // var dmList: DMList? = nil
    // var isFirstDM: Bool = false
    // var unreadCount: Int = 0
    
//    @Published var dmPeopleID: String?
//    var paginationDoc: QueryDocumentSnapshot?

    override func removeListeners() {
        super.removeListeners()
        messages.removeAll()
    }

    /// 채팅방 들어갔을때 실행하는 함수
    func setDMRoom(receiverUID: String) {
//        guard let currentUID = currentUID else{return}
        isLoading = true
        Task{
            do{
                let data = try await fetchDMPeopleID(receiverUID: receiverUID)
                self.dmPeopleRef = data.0
                self.currentDMListDocRef = data.1
                self.receiverDMListDocRef = data.2
                
                isReading = true
                dmListener(dmPeopleRef: self.dmPeopleRef)
            }catch{
                isLoading = false
                print("오류315")
            }
        }
    }
    /// DMList 경로와 dmPeopleRef 가져오는 함수
    private func getDMListDoc(uid: String, otherUID: String) async throws -> (DocumentReference?,DocumentReference?)? {
        do{
            let query = db.collection(strUsers).document(uid).collection(strDMList).whereField("receiverUID", isEqualTo: otherUID)
            let snapshot = try await query.getDocuments()
            let doc = snapshot.documents.first
            guard let docRef = doc?.reference else{return nil}
            let dmPeopleRef = doc?.get("dmPeopleRef") as? DocumentReference
    /*
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
            
            let users = DMPeople(chattersUID: [senderID,receiverID])
            let doc = self.db.collection("Users").document(senderID).collection(strDMList)
            
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
                            let chatter = DMList(chatterUID: receiverID, DMPeopleID: documentID, unreadMessages: 1)
                            try? doc.addDocument(from: chatter)
                        }
                    }
                    
                    let receiverDoc = self.db.collection("Users").document(receiverID).collection("Chatters")
                    receiverDoc.whereField("chatterUID", isEqualTo: senderID).getDocuments { querySnapshot, err in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else if querySnapshot!.documents.isEmpty {
                            let chatter = DMList(chatterUID: senderID, DMPeopleID: documentID, unreadMessages: 1)
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
                        let chatter = DMList(chatterUID: receiverID, DMPeopleID: documentID, unreadMessages: 1)
                        try doc.addDocument(from: chatter) { _ in
                            self.db.collection("DMPeople").document(documentID).collection("DM").addDocument(data: messageData)
                        }
                        let receiverDoc = self.db.collection("Users").document(receiverID).collection("Chatters")
                        let chatter2 = DMList(chatterUID: senderID, DMPeopleID: documentID, unreadMessages: 1)
                        try? receiverDoc.addDocument(from: chatter2)
                    } catch let error {
                        print("Error writing DMPeople document: \(error)")
                    }
                }
            }
        }*/
    
    func sendDM(message: String, receiverID: String) {
        if message.isEmpty {return}
        Task{
            do{
                guard let senderID = currentUID else{return}
                // 서버에 저장할 메시지
                let messageData = Message(message, uid: senderID)
                // 콜렉션 경로들
                let dmListCorrentCol = db.collection(strUsers).document(senderID).collection(strDMList)
                let dmListReceiverCol = db.collection(strUsers).document(receiverID).collection(strDMList)
                let dmPeopleCol = db.collection(strDMPeople)
                
                var dmID: String?
                
                // 본인 DMList에서 상대방과 DM데이터 검색 - DM방 나갔을시 검색안됨
                let dmListCurrentSnapshot = try await dmListCorrentCol.whereField("chatterUID", isEqualTo: receiverID).getDocuments()
                // 상대방 DMList 검색
                let dmListReceiverSnapshot = try await dmListReceiverCol.whereField("chatterUID", isEqualTo: senderID).getDocuments()
                
                if dmListCurrentSnapshot.documents.isEmpty {
                    // 상대방과 DM데이터 없을때
                    if dmListReceiverSnapshot.documents.isEmpty {
                        // 상대방도 DM데이터 없을때, DMPeople에서 상대방과 DM한 데이터 검색
                        var documentRef: DocumentReference?  // DMPeople 문서 경로
                        let dmPeopleSnapshot1 = try await dmPeopleCol.whereField("chattersUID", isEqualTo: [senderID,receiverID]).getDocuments()
                        let dmPeopleSnapshot2 = try await dmPeopleCol.whereField("chattersUID", isEqualTo: [receiverID,senderID]).getDocuments()
                        if dmPeopleSnapshot1.documents.isEmpty && dmPeopleSnapshot2.documents.isEmpty {
                            // 상대방과 첫 DM일때
                            let dmPeople = DMPeople(chattersUID: [senderID,receiverID])
                            // DMPeople 콜렉션에 문서 추가
                            documentRef = try await dmPeopleCol.addDocument(data: dmPeople.firestoreData)
                        } else {
                            // 상대방과 이전에 대화했을때 해당 문서 가져오기
                            var dmPeopleSnapshot: QuerySnapshot?
                            if dmPeopleSnapshot1.documents.isEmpty {
                                dmPeopleSnapshot = dmPeopleSnapshot2
                            } else {
                                dmPeopleSnapshot = dmPeopleSnapshot1
                            }
                            guard let document = dmPeopleSnapshot?.documents.first else{return}
                            documentRef = document.reference
                        }
                        guard let documentRef = documentRef else{return}
                        
                        dmID = documentRef.documentID  // DMPeople 문서 id
                        guard let dmID = dmID else{return}
                        let currentDMList = DMList(chatterUID: receiverID, DMPeopleID: dmID, unreadMessages: 1)
                        let receiverDMList = DMList(chatterUID: senderID, DMPeopleID: dmID, unreadMessages: 1)
                        
                        // 본인 DMList에 상대방과의 DM데이터 추가
                        let _ = try await dmListCorrentCol.addDocument(data: currentDMList.firestoreData)
                        print("본인DM추가")
                        // 상대방 DMList에 본인과의 DM데이터 추가
                        let _ = try await dmListReceiverCol.addDocument(data: receiverDMList.firestoreData)
                        print("상대DM추가")
                    } else {
                        // 상대방에 DM데이터 있을때
                        guard let document = dmListReceiverSnapshot.documents.first else{return}
                        dmID = document.get("DMPeopleID") as? String
                        guard let dmID = dmID else{return}
                        let currentDMList = DMList(chatterUID: receiverID, DMPeopleID: dmID, unreadMessages: 1)
                        // 본인 DMList에 상대방과의 DM데이터 추가
                        let _ = try await dmListCorrentCol.addDocument(data: currentDMList.firestoreData)
                        self.incrementUnreadMessages(receiverID: receiverID, chatRoomID: document.documentID)
                        
                    }
                } else {
                    // 상대방과 DM데이터 있을때
                    guard let document = dmListCurrentSnapshot.documents.first else{return}
                    dmID = document.get("DMPeopleID") as? String
                    if dmListReceiverSnapshot.documents.isEmpty {
                        // 상대방dp DM데이터 없을때, 상대방 DMList에 본인과의 DM데이터 추가
                        guard let dmID = dmID else{return}
                        let receiverDMList = DMList(chatterUID: senderID, DMPeopleID: dmID, unreadMessages: 1)
                        let _ = try await dmListReceiverCol.addDocument(data: receiverDMList.firestoreData)
                    } else {
                        guard let document = dmListReceiverSnapshot.documents.first else{return}
                        self.incrementUnreadMessages(receiverID: receiverID, chatRoomID: document.documentID)
                    }
                }
                guard let dmID = dmID else{return}
                // DMPeople 아까 만든 문서에 메시지 추가
                let _ = try await dmPeopleCol.document(dmID).collection(strDM).addDocument(data: messageData.firestoreData)
                
                self.fetchChatRoomID(receiverID: receiverID) { chatRoomID in
                    self.startListeningDM(chatterUID: receiverID)
                    self.resetUnreadMessages(userID: senderID, chatRoomID: chatRoomID)
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
            let chattersQuery = db.collection(strUsers).document(currentUID).collection(strDMList)
                .whereField("chatterUID", isEqualTo: chatterUID)
            let dmPeopleDoc = db.collection(strDMPeople)
            let dmPeopleQuery = dmPeopleDoc.whereField("users", arrayContains: chatterUID)
            
            do{
                let chattersSnapshot = try await chattersQuery.getDocuments()
                var dmPeopleID: String?
                
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
            }catch{
                print("오류!ifNoChatRemoveDMPeople")
            }
        }
    }
    
    func fetchPrevMessage(dmPeopleRef: DocumentReference?) {
        print("fetchPrevMessage")
        if !isReading {isLoading = false;return}
        guard let dmPeopleRef = dmPeopleRef else{return}
        guard let paginationDoc = paginationDoc else{isLoading = false;return}
        Task{
            do{                
                let query = dmPeopleRef.collection(strDM).order(by: "timestamp", descending: true)
                    .start(afterDocument: paginationDoc).limit(to: 30)
                let doc = try await query.getDocuments()
                
                let prevMessage = doc.documents.compactMap { document -> Message? in
                    document.data(as: Message.self)
                }
                if prevMessage.last == messages.last{isLoading = false;return}
                
                messages.append(contentsOf: prevMessage)
                if let lastDoc = doc.documents.last {
                    self.paginationDoc = lastDoc
                }
                await MainActor.run{
                    isLoading = false
                }
            }catch{
                isLoading = false
                print("오류fetchPrevMessage")
            }
        }
    }
    func dmListener(dmPeopleRef: DocumentReference?) {
        print("dmListener")
        guard let dmPeopleRef = dmPeopleRef else{return}
        let query = dmPeopleRef.collection(strDM)
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {self.handleErrorTask(error);return}
            
            guard let document = querySnapshot?.documents.first else{return}
            guard let data = document.data(as: Message.self) else{return}
            // 첫 실행이면 paginationDoc에 저장
            if self.paginationDoc == nil{
                self.paginationDoc = document
                self.fetchPrevMessage(dmPeopleRef: dmPeopleRef)
            }
            withAnimation {
                self.messages.insert(data, at: 0)
            }
            self.readDM()

        }
    }
//    func fetchPrevMessage(dmPeopleID: String) {
//        Task{
//            do{
//                guard let paginationDoc = paginationDoc else{return}
//                let query = db.collection(strDMPeople).document(dmPeopleID).collection(strDM).order(by: "timestamp", descending: true)
//                    .start(afterDocument: paginationDoc).limit(to: 20)
//                let doc = try await query.getDocuments()
//                let prevMessage = doc.documents.compactMap { document -> Message? in
//                    document.data(as: Message.self)
//                }
//                messages.append(contentsOf: prevMessage)
//            }catch{
//                print("오류fetchPrevMessage")
//            }
//        }
//    }
    
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
        
        let chatterDoc = db.collection(strUsers).document(currentUID).collection(strDMList)
        
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
            }.sorted{ $0.latestMessage > $1.latestMessage}
            self.isLoading = false
            print("Rooms:\(self.chattingRooms)")
        }
    }

    func leaveChatroom(chatroom: DMList) {
        guard let currentUID = currentUID else { return }
        let docRef = db.collection(strUsers).document(currentUID).collection(strDMList).document(chatroom.id ?? "")
        docRef.delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    /// 서버에 안 읽은 메시지 +1 저장
    func incrementUnreadMessages(receiverID: String, chatRoomID: String) {
        print("incrementUnreadMessages")
        let docRef = self.db.collection("Users").document(receiverID).collection(strDMList).document(chatRoomID)
       
        docRef.updateData([
            "unreadMessages": FieldValue.increment(Int64(1)),
            "latestMessage": Date()
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
        let docRef = Firestore.firestore().collection("Users").document(userID).collection(strDMList).document(chatRoomID)

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
        db.collection("Users").document(userUID).collection(strDMList).whereField("chatterUID", isEqualTo: receiverID).getDocuments { (snapshot, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            if let document = snapshot?.documents.first {
                completion(document.documentID)
            }
        }
    }
    
    func deleteRecentMessage(receiverID: String) {
//        isLoading = true
        guard let currentUID = currentUID else{return}
        let query = db.collection(strUsers).document(currentUID).collection(strDMList)
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


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

    var paginationDoc: QueryDocumentSnapshot?

    override func removeListeners() {
        super.init()
        messages.removeAll
    }
    
    func sendDM(message: String, receiverID: String) {
        if message.isEmpty {return}
        Task{
            do{
                guard let senderID = currentUID else{return}
                // 서버에 저장할 메시지
                let messageData = Message(message, uid: senderID)
                // 콜렉션 경로들
                let dmListCol = db.collection(strUsers).document(senderID).collection(strDMList)
                let dmPeopleCol = db.collection(strDMPeople)
                
                var dmID: String?
                
                // 본인 DMList에서 상대방과 DM데이터 검색 - DM방 나갔을시 검색안됨
                let dmListSnapshot = try await dmListCol.whereField("chatterUID", isEqualTo: receiverID).getDocuments()
                
                if dmListSnapshot.documents.isEmpty {
                    // 상대방과 DM데이터 없을때
                    var documentRef: DocumentReference?  // DMPeople 문서 경로
                    // DMPeople에서 상대방과 DM한 데이터 검색
                    let dmPeopleSnapshot = try await dmPeopleCol.whereField("chattersUID", arrayContains: receiverID).getDocuments()
                    if dmPeopleSnapshot.documents.isEmpty {
                        // 상대방과 첫 DM일때
                        let dmPeople = DMPeople(chattersUID: [senderID,receiverID])
                        // DMPeople 콜렉션에 문서 추가
                        documentRef = try await dmPeopleCol.addDocument(data: dmPeople.firestoreData)
                    } else {
                        // 상대방과 이전에 대화했을때 해당 문서 가져오기
                        guard let document = dmPeopleSnapshot.documents.first else{return}
                        documentRef = document.reference
                    }
                    guard let documentRef = documentRef else{return}
                    
                    dmID = documentRef.documentID  // DMPeople 문서 id
                    guard let dmID = dmID else{return}
                    let chatter = DMList(chatterUID: receiverID, DMPeopleID: dmID)
                    // 본인 DMList에 상대방과의 DM데이터 추가
                    let _ = try await dmListCol.addDocument(data: chatter.firestoreData)
                } else {
                    // 상대방과 DM데이터 있을때
                    guard let document = dmListSnapshot.documents.first else{return}
                    dmID = document.get("DMPeopleID") as? String
                }
                guard let dmID = dmID else{return}
                // DMPeople 아까 만든 문서에 메시지 추가
                let _ = try await dmPeopleCol.document(dmID).collection(strDM).addDocument(data: messageData.firestoreData)
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
                let query = dmDoc.order(by: "timestamp", descending: true)
                            .limit(to: 20)
                // .limit(to: 25)  
                // if paged == nil {
                //     query = query
                    
                // } else {

                // }
                // guard let lastSnapshot = snapshot.documents.last else {
                //     return
                // }
                // let next = db.collection("cities")
                // .order(by: "population")
                // .start(afterDocument: lastSnapshot)
                
                let listener = query.addSnapshotListener { querySnapshot, error in
                    if let error = error {self.handleErrorTask(error);return}
                    guard let querySnapshot = querySnapshot else {return}

                    querySnapshot.documentChanges.forEach { diff in
                        if (diff.type == .added) {
                            if paginationDoc == nil{
                                self.messages.append(diff.document.data(as: Message.self))
                            } else {
                                self.messages.insert(diff.document.data(as: Message.self, at: 0))
                            }
                        } 
                    }
                    
                    // self.messages = querySnapshot.documents.compactMap { document -> Message? in
                    //     document.data(as: Message.self)
                    // }
                    self.paginationDoc = querySnapshot.documents.last
                }
                listeners[query.description] = listener
            } catch {
                handleErrorTask(error)
            }
        }
    }
    func fetchPrevMessage() {
        Task{
            do{
                let query = db.collection(strDMPeople).document(dmPeopleID).collection(strDM).order(by: "timestamp", descending: true)
                            .startAfter(at: paginationDoc.limit(to: 20))//.start(afterDocument: paginationDoc)
                let doc = try await query.getDocuments()
                let prevMessage = doc.documents.compactMap { document -> Message? in
                    document.data(as: Message.self)
                }
                messages.append(contentsOf: prevMessage)
            }catch{
                print("오류fetchPrevMessage")
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
            }
            self.isLoading = false
            print("Rooms:\(self.chattingRooms)")
        }
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
    /// 서버에 안 읽은 메시지 +1 저장
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


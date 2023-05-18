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
    
    var dmPeopleID: String? = nil
    var currentDMListDoc: DocumentReference? = nil
    var receiverDMListDoc: DocumentReference? = nil
    
    var dmList: DMList? = nil
    var isFirstDM: Bool = false
    var unreadCount: Int = 0
    
//    var paginationDoc: QueryDocumentSnapshot?
    override init() {
        super.init()
        print("viewmodel")
    }

    override func removeListeners() {
        print("removeListeners")
        super.removeListeners()
//        messages.removeAll()
    }
    
    func setDmPeopleID(dmPeopleID: String? = nil, receiverUID: String) {
        guard let currentUID = currentUID else{return}
        Task{
            do{
                if let dmPeopleID = dmPeopleID {
                    self.dmPeopleID = dmPeopleID
                    let query = db.collection(strUsers).document(currentUID).collection(strDMList).whereField("DMPeopleID", isEqualTo: dmPeopleID)
                    let snapshot = try await query.getDocuments()
                    currentDMListDoc = snapshot.documents.first?.reference
                } else {
                    self.dmPeopleID = try await fetchDMPeopleID(receiverUID: receiverUID)
                }
                updateReadTime()
            }catch{
                print("오류315")
            }
        }
    }

    func fetchDMPeopleID(receiverUID: String) async throws -> String? {
        print("fetchDMPeopleID")
        guard let currentUID = currentUID else{throw SomeError.missCurrentUID}
        do{
            // 콜렉션 경로들
            let dmListCorrentCol = db.collection(strUsers).document(currentUID).collection(strDMList)     // 사용자 DMLIst경로
            let dmListReceiverCol = db.collection(strUsers).document(receiverUID).collection(strDMList)  // 상대방 DMList경로
            let dmPeopleCol = db.collection(strDMPeople)
            // 사용자 DMList에서 상대방과 DM데이터 검색 - DM방 나갔을시 DMPeople 콜렉션에 데이터 있어도 사용자 DMList에 없음
            let dmListSenderSnapshot = try? await dmListCorrentCol.whereField("chatterUID", isEqualTo: receiverUID).getDocuments()
            // 상대방 DMList에서 사용자와 DM데이터 검색
            let dmListReceiverSnapshot = try? await dmListReceiverCol.whereField("chatterUID", isEqualTo: currentUID).getDocuments()
            // DMList 문서 데이터 없으면 nil
            let currentDMList = dmListSenderSnapshot?.documents.first
            let receiverDMList = dmListReceiverSnapshot?.documents.first
            // DMListDoc 저장 없으면 nil
            currentDMListDoc = currentDMList?.reference
            receiverDMListDoc = receiverDMList?.reference
            
            var dmPeopleID: String?
            
            if let currentDMList = currentDMList, let _ = receiverDMList {
                // 사용자와 상대방 모두 DMList에 서로간 DM데이터 있을때
                dmPeopleID = currentDMList.get("DMPeopleID") as? String
                
            } else if let currentDMList = currentDMList {
                // 사용자 DMList에만 상대방과 DM데이터 있을때
                dmPeopleID = currentDMList.get("DMPeopleID") as? String
                // 상대방 DMList에 사용자와의 DM데이터 문서 생성
                guard let dmPeopleID = dmPeopleID else{throw SomeError.missSomething}
                let receiverDMList = DMList(chatterUID: currentUID, DMPeopleID: dmPeopleID)
                let receiverDMListRef = try await dmListReceiverCol.addDocument(data: receiverDMList.firestoreData)
                // DMListDoc 저장
                receiverDMListDoc = receiverDMListRef
                print("ㅇ4")
            } else if let receiverDMList = receiverDMList {
                // 상대방 DMList에만 사용자와 DM데이터 있을때
                dmPeopleID = receiverDMList.get("DMPeopleID") as? String
                // 사용자 DMList에 상대방과의 DM데이터 문서 생성
                guard let dmPeopleID = dmPeopleID else{throw SomeError.missSomething}
                let currentDMList = DMList(chatterUID: receiverUID, DMPeopleID: dmPeopleID)
                let currentDMListRef = try await dmListCorrentCol.addDocument(data: currentDMList.firestoreData)
                // DMListDoc 저장
                currentDMListDoc = currentDMListRef
                print("ㅇ5")
            } else {
                print("ㅇ6")
                // 둘 다 DMList에 서로간의 DM데이터가 없을때, DMPeople 콜렉션에서 검색
                let query = dmPeopleCol.whereField("chattersUID", arrayContainsAny: [currentUID,receiverUID])
                let dmPeopleSnapshot = try await query.getDocuments()
                print("7")
                if let dmPeopleDoc = dmPeopleSnapshot.documents.first {
                    // 상대방과 이전에 대화기록 있을때
                    dmPeopleID = dmPeopleDoc.documentID
                } else {
                    // 상대방과 첫 DM일때, DMPeople에 문서 생성
                    let dmPeople = DMPeople(chattersUID: [currentUID,receiverUID])
                    let documentRef = try await dmPeopleCol.addDocument(data: dmPeople.firestoreData)
                    dmPeopleID = documentRef.documentID
                }
                print("ㅇ7")
                guard let dmPeopleID = dmPeopleID else{throw SomeError.missSomething}
                // 사용자 DMList에 상대방과의 DM데이터 문서 생성
                let currentDMList = DMList(chatterUID: receiverUID, DMPeopleID: dmPeopleID)
                let currentDMListRef = try await dmListCorrentCol.addDocument(data: currentDMList.firestoreData)
                // 상대방 DMList에 사용자와의 DM데이터 문서 생성
                let receiverDMList = DMList(chatterUID: currentUID, DMPeopleID: dmPeopleID)
                let receiverDMListRef = try await dmListReceiverCol.addDocument(data: receiverDMList.firestoreData)
                // DMListID 저장
                currentDMListDoc = currentDMListRef
                receiverDMListDoc = receiverDMListRef
            }
            print("ㅇ8")
            guard let currentDMListDoc = currentDMListDoc else{throw SomeError.missSomething}
            dmList = try await currentDMListDoc.getDocument(as: DMList.self)
            print("9ㅇ")
            
            return dmPeopleID
        }catch{
            print("오류!패치디엠피플아이디:\(error.localizedDescription)")
            return nil
        }
        
    }
    
    func updateReadTime(){
        print("updateReadTime")
        guard let currentDMListDoc = currentDMListDoc else{return}
        Task{
            try await currentDMListDoc.updateData(DMList.firestoreUpdate)
        }
        
    }

    func sendDM(message: String) {
        print("sendDM")
        if message.isEmpty {return}
        Task{
            do{
                guard let senderUID = currentUID,
                      let dmPeopleID = dmPeopleID else{print("sendDM오류");return}
                // 서버에 저장할 메시지
                let messageData = Message(message, uid: senderUID)
                let dmCol = db.collection(strDMPeople).document(dmPeopleID).collection(strDM)
                
                // DMPeople - DM에 메시지 생성
                let _ = try await dmCol.addDocument(data: messageData.firestoreData)
            }catch{
                print("오류!sendDM")
            }
        }
    }
    
    func ifNoChatRemoveDoc() {
        print("ifNoChatRemoveDoc")
        Task{
            do{
                guard let dmPeopleID = dmPeopleID,
                      let currentDMListDoc = currentDMListDoc,
                      let receiverDMListDoc = receiverDMListDoc else{print("sendDM오류");return}
                
                let dmPeopleDoc = db.collection(strDMPeople).document(dmPeopleID)
                
                let snapshot = try await dmPeopleDoc.collection(strDM).limit(to: 1).getDocuments()
                print("snapshot:\(snapshot)")
                
                if snapshot.isEmpty{
                    try await currentDMListDoc.delete()
                    try await receiverDMListDoc.delete()
                    try await dmPeopleDoc.delete()
                }
            }catch{
                print("오류!ifNoChatRemoveDMPeople")
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
                
                guard let dmPeopleID = dmPeopleID else {return}
                
                let dmDoc = dmPeopleDoc.document(dmPeopleID).collection(self.strDM)
                let query = dmDoc.order(by: "timestamp")//, descending: true)
//                            .limit(to: 20)
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

//                    querySnapshot.documentChanges.forEach { diff in
//                        if (diff.type == .added) {
//                            guard let data = diff.document.data(as: Message.self) else{return}
//                            if self.paginationDoc == nil{
//                                self.messages.append(data)
//                            } else {
//                                self.messages.insert(data, at: 0)
//                            }
//                        }
//                    }
                    
                     self.messages = querySnapshot.documents.compactMap { document -> Message? in
                         document.data(as: Message.self)
                     }
//                    self.paginationDoc = querySnapshot.documents.last
                }
                listeners[query.description] = listener
            } catch {
                handleErrorTask(error)
            }
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
        let query = db.collection(strDMPeople).document(dmPeopleID).collection(strDM)
                    .order(by: "timestamp")

        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {self.handleErrorTask(error);return}
            
            guard let documents = querySnapshot?.documents else{return}
            // 쿼리 결과를 DM 객체의 배열로 변환하고, 이를 messages 배열에 저장합니다.
            self.messages = documents.compactMap { document -> Message? in
                document.data(as: Message.self)
            }
            self.updateReadTime()
        }
        listeners[query.description] = listener
    }
    
    func leaveChatroom(dmPeopleID: String) {
        print("leaveChatroom")
        guard let currentDMListDoc = currentDMListDoc else { return }
        Task{
            try await currentDMListDoc.delete()
        }
    }
    
    
    func dmListListener() {
        print("dmListListener")
        guard let currentUID = currentUID else{return}
        isLoading = true
        
        let dmListCol = db.collection(strUsers).document(currentUID).collection(strDMList)
        
        let listener = dmListCol.addSnapshotListener{ querySnapshot, error in
            if let error = error {self.handleErrorTask(error);return}
            
            guard let querySnapshot = querySnapshot else {self.isLoading = false;return}
            querySnapshot.documentChanges.forEach{ diff in
                if (diff.type == .added) {
                    print("add city: \(diff.document.data())")
                }
                if (diff.type == .modified) {
                   print("Modified city: \(diff.document.data())")
                }
                if (diff.type == .removed) {
                   print("Removed city: \(diff.document.data())")
                }
            }
            self.chattingRooms = querySnapshot.documents.compactMap{ document -> DMList? in
                document.data(as: DMList.self)
            }.sorted{ $0.latestReadTime > $1.latestReadTime}
            self.isLoading = false
        }
        
        listeners[dmListCol.path] = listener
    }

    func fetchUnreadCount() {
        print("fetchUnreadCount")
        unreadCount = 0
        guard let dmList = dmList else{return}
        messages.forEach{ message in
            if message.timestamp.dateValue() > dmList.latestReadTime{
                unreadCount += 1
            }
        }
    }
}


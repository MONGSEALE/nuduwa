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
    var isReady: Bool = false
    
    
    // var dmList: DMList? = nil
    // var isFirstDM: Bool = false
    // var unreadCount: Int = 0
    
    override func removeListeners() {
        print("removeListeners")
        super.removeListeners()
        messages.removeAll()
        chattingRooms.removeAll()
    }

    func readLastDM(){
        isReady = true
    }

    /// 채팅방 들어갔을때 실행하는 함수
    func setDMRoom(receiverUID: String) {
        guard let currentUID = currentUID else{return}
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
            
            return (docRef, dmPeopleRef)
        }catch{
            throw SomeError.error
        }
    }
    /// dmPeopleRef와 사용자, 상대방 DMList 경로 가져오는 함수
    private func fetchDMPeopleID(receiverUID: String) async throws -> (DocumentReference, DocumentReference, DocumentReference) {
        print("fetchDMPeopleID")
        guard let currentUID = currentUID else{throw SomeError.missCurrentUID}
        do{
            // 콜렉션 경로들
            let dmListCorrentCol = db.collection(strUsers).document(currentUID).collection(strDMList)     // 사용자 DMLIst경로
            let dmListReceiverCol = db.collection(strUsers).document(receiverUID).collection(strDMList)  // 상대방 DMList경로
            let dmPeopleCol = db.collection(strDMPeople)

            var dmPeopleDocRef: DocumentReference?
            var currentDocRef: DocumentReference?
            var receiverDocRef: DocumentReference?
            
            if let data = try await self.getDMListDoc(uid: currentUID, otherUID: receiverUID) {
                currentDocRef = data.0
                dmPeopleDocRef = data.1
            }
        
            if let data = try await getDMListDoc(uid: receiverUID, otherUID: currentUID) {
                receiverDocRef = data.0
                dmPeopleDocRef = data.1
            }

            if currentDocRef != nil && receiverDocRef != nil{
                // 사용자와 상대방 모두 DMList에 서로간 DM데이터 있을때
                print("사용자와 상대방 모두 DMList에 서로간 DM데이터 있음")
            } else if currentDocRef != nil {
                // 사용자 DMList에만 상대방과 DM데이터 있을때,
                // 상대방 DMList에 사용자와의 DM데이터 문서 생성
                print("사용자만 DMList에 상대방 DM데이터 있음")
                guard let dmPeopleDocRef = dmPeopleDocRef else{throw SomeError.missSomething}
                let receiverDMList = DMList(receiverUID: currentUID, dmPeopleRef: dmPeopleDocRef)
                let receiverDMListRef = try await dmListReceiverCol.addDocument(data: receiverDMList.firestoreData)
                // DMListDocRef 저장
                receiverDocRef = receiverDMListRef
            } else if receiverDocRef != nil {
                // 사용자 DMList에만 상대방과의 DM데이터 없을때,
                // 사용자 DMList에 상대방과의 DM데이터 문서 생성
                print("상대방만 DMList에 사용자 DM데이터 있음")
                guard let dmPeopleDocRef = dmPeopleDocRef else{throw SomeError.missSomething}
                let currentDMList = DMList(receiverUID: receiverUID, dmPeopleRef: dmPeopleDocRef)
                let currentDMListRef = try await dmListCorrentCol.addDocument(data: currentDMList.firestoreData)
                // DMListDocRef 저장
                currentDocRef = currentDMListRef
            } else {
                // 둘 다 DMList에 서로간의 DM데이터가 없을때, DMPeople 콜렉션에서 검색
                print("사용자와 상대방 모두 DMList에 서로간 DM데이터 없음")
                let query = dmPeopleCol.whereField("chattersUID", arrayContainsAny: [currentUID,receiverUID])
                let dmPeopleSnapshot = try await query.getDocuments()

                if let dmPeopleDoc = dmPeopleSnapshot.documents.first {
                    // 상대방과 이전에 대화기록 있을때
                    dmPeopleDocRef = dmPeopleDoc.reference
                } else {
                    // 상대방과 첫 DM일때, DMPeople에 문서 생성
                    let dmPeople = DMPeople(chattersUID: [currentUID,receiverUID])
                    let documentRef = try await dmPeopleCol.addDocument(data: dmPeople.firestoreData)
                    dmPeopleDocRef = documentRef
                }
                guard let dmPeopleDocRef = dmPeopleDocRef else{throw SomeError.missSomething}
                // 사용자 DMList에 상대방과의 DM데이터 문서 생성
                let currentDMList = DMList(receiverUID: receiverUID, dmPeopleRef: dmPeopleDocRef)
                let currentDMListRef = try await dmListCorrentCol.addDocument(data: currentDMList.firestoreData)
                // 상대방 DMList에 사용자와의 DM데이터 문서 생성
                let receiverDMList = DMList(receiverUID: currentUID, dmPeopleRef: dmPeopleDocRef)
                let receiverDMListRef = try await dmListReceiverCol.addDocument(data: receiverDMList.firestoreData)
                // DMListDocRef 저장
                currentDocRef = currentDMListRef
                receiverDocRef = receiverDMListRef
            }
            guard let dmPeopleDocRef = dmPeopleDocRef,
                  let receiverDocRef = receiverDocRef,
                  let currentDocRef = currentDocRef else{throw SomeError.missSomething}
            return (dmPeopleDocRef, currentDocRef, receiverDocRef)
        }catch{
            print("오류!패치디엠피플아이디:\(error.localizedDescription)")
            throw SomeError.error
        }
        
    }
    /// 채팅방 들어가서 리스닝 실행중에 사용자 DMList 필드 unreadMessages를 0으로 변경
    func readDM() {
        print("readDM")
        if isReading {
            guard let currentDMListDocRef = currentDMListDocRef else{return}
            Task{
                try await currentDMListDocRef.updateData(DMList.readDM)
            }
        }
    }
    /// 메시지 보내기
    func sendDM(message: String) {
        print("sendDM")
        if message.isEmpty {return}
        Task{
            do{
                guard let senderUID = currentUID,
                      let dmPeopleRef = dmPeopleRef,
                      let currentDMListDocRef = currentDMListDocRef,
                      let receiverDMListDocRef = receiverDMListDocRef else{print("sendDM오류");return}
                // 서버에 저장할 메시지
                let messageData = Message(message, uid: senderUID)
                let dmCol = dmPeopleRef.collection(strDM)
                
                // DMPeople - DM에 메시지 생성
                let _ = try await dmCol.addDocument(data: messageData.firestoreData)
                // 비동기로 2개작업 동시에 실행
                await withThrowingTaskGroup(of: Void.self) { group in
                    // 사용자 DMList 업데이트
                    group.addTask {
                        do {
                            try await currentDMListDocRef.updateData(DMList.firestoreUpdate)
                        } catch {
                            throw error
                        }
                    }
                    // 상대방 DMList 업데이트
                    group.addTask {
                        do {
                            try await receiverDMListDocRef.updateData(DMList.firestoreUpdate)
                        } catch {
                            throw error
                        }
                    }
                }
            }catch{
                print("오류!sendDM")
            }
        }
    }
    /// 아무런 채팅도 안치고 채팅방 나가면 사용자, 상대방 DMList 문서 삭제
    func ifNoChatRemoveDoc() {
        print("ifNoChatRemoveDoc")
        Task{
            do{
                guard let dmPeopleRef = dmPeopleRef,
                      let currentDMListDocRef = currentDMListDocRef,
                      let receiverDMListDocRef = receiverDMListDocRef else{print("sendDM오류");return}
                
                let snapshot = try await dmPeopleRef.collection(strDM).limit(to: 1).getDocuments()
                
                if snapshot.isEmpty{
                    // 비동기로 3개작업 동시에 실행
                    await withThrowingTaskGroup(of: Void.self) { group in
                        // 사용자 DMList 삭제
                        group.addTask {
                            do {
                                try await currentDMListDocRef.delete()
                            } catch {
                                throw error
                            }
                        }
                        // 상대방 DMList 삭제
                        group.addTask {
                            do {
                                try await receiverDMListDocRef.delete()
                            } catch {
                                throw error
                            }
                        }
                        // DMPeople 문서 삭제
                        group.addTask {
                            do {
                                try await dmPeopleRef.delete()
                            } catch {
                                throw error
                            }
                        }
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
                messages.insert(contentsOf: prevMessage.reversed(), at: 0)
                if let lastDoc = doc.documents.last {
                    self.paginationDoc = lastDoc
                }
                isLoading = false
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
            self.messages.append(data)
            self.readDM()
        }
        listeners[query.description] = listener
    }
    
    func leaveChatroom(receiverUID: String) {
        print("leaveChatroom")
        guard let currentUID = currentUID else{return}
        Task{
            do{
                if currentDMListDocRef == nil {
                    let doc = try await getDMListDoc(uid: currentUID, otherUID: receiverUID)
                    self.currentDMListDocRef = doc?.0
                }
                guard let currentDMListDocRef = currentDMListDocRef else{throw SomeError.missSomething}
                try await currentDMListDocRef.delete()
            }catch{
                print("오류")
            }
        }
    }
    
    
    func dmListListener() {
        print("dmListListener")
        guard let currentUID = currentUID else{return}
        isLoading = true

        let dmListCol = db.collection(strUsers).document(currentUID).collection(strDMList)
        
        let listener = dmListCol.addSnapshotListener{ querySnapshot, error in
            if let error = error {self.handleErrorTask(error);return}
            guard let querySnapshot else{return}
            
            querySnapshot.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    guard let data = diff.document.data(as: DMList.self) else{return}
                    print("추가: \(diff.document.data())")
                    self.chattingRooms.append(data)
                }
                
                if (diff.type == .modified) {
                    guard let data = diff.document.data(as: DMList.self) else{return}
                    print("변경: \(diff.document.data())")
                    self.chattingRooms.append(data)
                }
            }
            self.chattingRooms = self.chattingRooms.sorted{ $0.latestMessage > $1.latestMessage}
            
//            self.chattingRooms = querySnapshot?.documents.compactMap{ document -> DMList? in
//                document.data(as: DMList.self)
//            }.sorted{ $0.latestMessage > $1.latestMessage} ?? []
            self.isLoading = false
        }
        listeners[dmListCol.path] = listener
    }

//    func fetchUnreadCount() {
//        print("fetchUnreadCount")
//        unreadCount = 0
//        guard let dmList = dmList else{return}
//        messages.forEach{ message in
//            if message.timestamp.dateValue() > dmList.latestReadTime{
//                unreadCount += 1
//            }
//        }
//    }
}


    /*
    func updateReadTime(){
        print("updateReadTime")
        guard let currentDMListDocRef = currentDMListDocRef else{return}
        Task{
            try await currentDMListDocRef.updateData(DMList.firestoreUpdate)
        }
    }*/
/*
    querySnapshot.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    guard let data = diff.document.data(as: Message.self) else{return}
                    if self.paginationDoc == nil{
                        print("nil")
                        self.messages = [data]
                        self.paginationDoc = diff.document
                    } else {
                        print("nonil")
                        self.messages.append(data)
                    }
                    print("추가: \(diff.document.data())")
                }
                
                if (diff.type == .modified) {
                    guard let data = diff.document.data(as: Message.self) else{return}
                    if self.paginationDoc == nil{
                        print("nil")
                        self.messages = [data]
                        self.paginationDoc = diff.document
                    } else {
                        print("nonil")
                        self.messages.append(data)
                    }
                    print("변경: \(diff.document.data())")
                }
            }
            */

//
//  DMViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import Foundation
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
    
    @Published var isBlocked: Bool = false  // 유저한테 차단됨
    @Published var blocked:Bool = false  // 유저를 차단함
    
    var receiverUID: String? = nil
    
    override func removeListeners() {
        super.removeListeners()
        messages.removeAll()
    }
    
    /// 채팅방 들어갔을때 실행하는 함수
    func setDMRoom(receiverUID: String) {
        isLoading = true
        Task{
            do{
                let data = try await fetchDMPeopleID(receiverUID: receiverUID)
                self.dmPeopleRef = data.0
                self.currentDMListDocRef = data.1
                self.receiverDMListDocRef = data.2
                
                self.receiverUID = receiverUID
                self.blockListListener()
                
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
    /// dmPeople경로, currentDMList경로, receiverDMList경로 리턴함
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
            print("상대방:\(receiverUID)")
            
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
                let query = dmPeopleCol.whereField("chattersUID", arrayContains: currentUID)
                let dmPeopleSnapshot = try await query.getDocuments()
                
                for document in dmPeopleSnapshot.documents {
                    let peopleUID = document.data()["chattersUID"] as? [String] ?? []
                    if peopleUID.contains(receiverUID) {
                        print("이전 대화있음:\(currentUID),\(receiverUID)")
                        dmPeopleDocRef = document.reference
                    }
                }
                if dmPeopleDocRef == nil {
                    print("이전 대화없음:\(currentUID),\(receiverUID)")
                    // 상대방과 첫 DM일때, DMPeople에 문서 생성
                    let dmPeople = DMPeople(chattersUID: [currentUID,receiverUID])
                    print("1")
                    let documentRef = try await dmPeopleCol.addDocument(data: dmPeople.firestoreData)
                    print("2")
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
            print("오키")
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
                      let receiverUID = receiverUID,
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
                    group.addTask {
                        do {
                            // 상대방이 차단했는지 확인
                            let query = self.db.collection(self.strUsers).document(receiverUID).collection(self.strBlockList).whereField("blockUID", isEqualTo: senderUID)
                            let snapshot = try await query.getDocuments()
                            print("snapshot:\(snapshot)")
                            if snapshot.documents.first == nil {
                                try await receiverDMListDocRef.updateData(DMList.firestoreUpdate)
                            }
                        } catch {
                            throw error
                        }
                    }
                    
                }
                readDM()
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
    func dmListener(dmPeopleRef: DocumentReference?, listenerKey: String? = nil) {
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
            self.messages.insert(data, at: 0)
            self.readDM()
        }
        if let key = listenerKey {
            listeners[key] = listener
        } else {
            listeners[query.description] = listener
        }
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
                try await currentDMListDocRef.updateData(DMList.disAppear)
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
            
            self.chattingRooms = querySnapshot.documents.compactMap{ document -> DMList? in
                document.data(as: DMList.self)
            }
            self.isLoading = false
        }
        listeners[dmListCol.path] = listener
    }
    
    // 차단여부확인
    func blockListListener() {
        guard let currentUID,
              let receiverUID else{return}
        Task{
            // 내가 차단했는지 확인
            let currentQuery = self.db.collection(self.strUsers).document(currentUID).collection(self.strBlockList).whereField("blockUID", isEqualTo: receiverUID)
            let currentListener = currentQuery.addSnapshotListener{ snapshot, error in
                print("블락유저")
                if let error {print("blockListListener에러: \(error)");return;}
                
                guard let snapshot else{return}
                if snapshot.documents.first != nil {
                    // 내가 차단했으면 isBlocked = true
                    self.blocked = true
                } else {
                    self.blocked = false
                }
                
            }
            listeners[currentQuery.description] = currentListener
            
            // 상대방이 차단했는지 확인
            let receiverQuery = self.db.collection(self.strUsers).document(receiverUID).collection(self.strBlockList).whereField("blockUID", isEqualTo: currentUID)
            let receiverListener = receiverQuery.addSnapshotListener{ snapshot, error in
                print("블락상대방")
                if let error {print("blockListListener에러: \(error)");return;}
                guard let snapshot else{return}
                if snapshot.documents.first != nil {
                    // 상대방이 차단했으면 isBlocked = true
                    self.isBlocked = true
                } else {
                    self.isBlocked = false
                }
            }
            listeners[receiverQuery.description] = receiverListener
        }
    }
}


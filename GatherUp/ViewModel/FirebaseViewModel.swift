//
//  MeetingViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/05.
//

import SwiftUI
import Firebase
import FirebaseFirestore

class FirebaseViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []     // 모임 배열
    var fetchedMeetings: [Meeting] = []         // 서버에서 가져오는 모임 배열
    @Published var newMeeting: Meeting?         // 새로 추가하는 모임(저장전)
    @Published var meeting: Meeting?            // 모임
    
    @Published var isOverlap: Bool = false
    
    /// 에러 처리 변수
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var isLoading: Bool = false
    @Published var isFetching: Bool = true
    
    @Published var members: [Members] = []
    
    private var docListner: ListenerRegistration?
    
    //chat기능 변수
    private let db = Firestore.firestore()
    private let strMeetings = "Meetings"        // Firestore에 저장된 콜렉션 이름
    private let strMembers = "Members"          // Firestore에 저장된 콜렉션 이름
    private let strMessage = "Message"          // Firestore에 저장된 콜렉션 이름
    @Published var messages: [ChatMessage] = []
    //private var cancellables = Set<AnyCancellable>()
    private var listenerRegistration: ListenerRegistration?
    
//    func arrayMeetings(){
//        guard let uid = Auth.auth().currentUser?.uid else{return}
//        ForEach(meetings){ meeting in
//            meeting
//        }
//        meetings.lastIndex(of: )
//    }
    
    /// 서버 모임과 새로 추가하는 모임(서버 저장전) 배열 합치기
    func combineMeetings(){
        meetings = (newMeeting != nil) ? fetchedMeetings + [newMeeting!] : fetchedMeetings
    }
    /// Firestore에 있는 모임 데이터 가져오기
//    func fetchMeetings(passedMeeting: Bool = false)async{
//        do{
//            print("fetchMeetings 실행")
//            guard let uid:String = Auth.auth().currentUser?.uid else{return}
//
//            var query: Query!
//
//            query = Firestore.firestore().collection("Meetings")
//            //                    .whereField("members", arrayContains: uid)
//                .order(by: "meetingDate", descending: true)
//            //            if passedMeeting {
//            //                query = query.whereField("meetingDate", isLessThan: Date())
//            //            } else {
//            //                query = query.whereField("meetingDate", isGreaterThan: Date())
//            //            }
//
//            let docs = try await query.getDocuments()
//            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
//                try? doc.data(as: Meeting.self)
//            }
//            print("fetchedMeetings")
//            await MainActor.run(body: {
//                meetings = fetchedMeetings
//                isFetching = false
//            })
//        }catch{
//            print("fetchMeetings 에러!")
//        }
//    }

    /// 실시간 모임 추가시 meetings 배열에 데이터 추가
    func meetingsListner(isJoin: Bool = false){
        print("addListner")
        guard let uid = Auth.auth().currentUser?.uid else{return}
        let doc = isJoin ? db.collectionGroup(strMembers).whereField("memberId", isEqualTo: uid) : db.collection("Meetings")
        print("doc: \(doc)")
        docListner = doc.addSnapshotListener { (snapshot, error) in
                guard let documents = snapshot?.documents else {
                    print("No documents")
                    return
                }
                self.fetchedMeetings = documents.compactMap{ documents -> Meeting? in
                    try? documents.data(as: Meeting.self)
                }
                self.combineMeetings()
            }
    }
    
    /// 리스너 제거(리소스 확보)
    func removeListner(){
        if let docListner{
            docListner.remove()
            self.docListner = nil
        }
    }
    /// 모임 추가시(서버 저장전)
    func addMeeting(newMeeting: Meeting){
        self.newMeeting = newMeeting
        combineMeetings()
    }
    /// 모임 추가 취소 또는 모임 서버 저장했을때 newMeeting 초기화
    func cancleMeeting(){
        newMeeting = nil
        combineMeetings()
    }
    /// 새로운 모임 Firestore에 저장
    func createMeeting(meeting: Meeting){
        //isLoading = true
        //showKeyboard = false
        Task{
            do{
                /// - Firestore에 저장
                print("firebase save")
//                let document = try await db.collection(strMeetings).addDocument(from: meeting)
//                let meetingId = document.documentID
//                print("Meeting ID: \(meetingId)")
//                try await joinMeeting(meetingId: meetingId)
                guard let uid = Auth.auth().currentUser?.uid else{return}
                let _ = try db.collection(strMeetings).document().setData(from: meeting, completion: {error in
                    if let error = error{
                        print("Error CreateMeeting: \(error)")
                    } else {
                        print("모임 추가 완료")
                    }
                })

//                let meetingId = try await db.collection(strMeetings).whereField("hostId", isEqualTo: uid).getDocuments().documents.compactMap { doc -> String? in
//                    let id = doc.documentID
//                    print("id: \(id)")
//
//                    self.joinMeeting(meetingId: id)
//                    return id
//                }
//                try await print(meetingId)
//                await joinMeeting(meetingId: meetingId[0])
//
            } catch {
                await handleError(error: error)
                //isLoading = false
            }
        }
    }
    /// 작성자 중복 확인
    func checkedOverlap(id: String?){
        if id==nil {
            print("아이디가 NULL임")
            self.isOverlap = true
            return
        }else{
            let doc = db.collection(strMeetings).whereField("hostUID", isEqualTo: id!)
            doc.getDocuments(){ (query, err) in
                if let err = err {
                    print("checkedOverlap 에러: \(err)")
                } else {
                    print("중복 여부")
                    if let query = query, !query.isEmpty {
                        print("중복!: \(query.documents)")
                        self.isOverlap = true
                    } else {
                        print("중복 아님!")
                        self.isOverlap = false
                    }
                }
            }
        }
    }
    
    /// 모임 참가하기
    func joinMeeting(meetingId: String){
        print("joinMeeting")
        Task{
            do{
                guard let user = Auth.auth().currentUser else{return}
                let member = Members(memberId: user.uid, memberName: user.displayName!, memberImage: user.photoURL)
                let doc = db.collection(strMeetings).document(meetingId).collection(strMembers).document()
//                let doc = db.document(meetingId).collection("members").document()
                let _ = try doc.setData(from: member, completion: {error in
                    if let error = error{
                        print("Error CreateMeeting: \(error)")
                    } else {
                        print("모임 추가 완료")
                    }
                })
            } catch {
                await handleError(error: error)
                //isLoading = false
            }
        }
    }
    
    ///모임 나가기
    func leaveMeeting(meetingId: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let doc = db.collection(strMeetings).document(meetingId).collection(strMembers)

        doc.whereField("memberId", isEqualTo: currentUser.uid).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting user document: \(error)")
            } else {
                guard let documents = snapshot?.documents else { return }
                for document in documents {
                    doc.document(document.documentID).delete()
                }
            }
        }
    }

    /// 모임맴버 가져오기
    func membersListener(meetingId: String){
        docListner = db.collection(strMeetings).document(meetingId).collection(strMembers)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {return}
                documents.forEach{document in
                    self.members = documents.compactMap{ documents -> Members? in
                        try? documents.data(as: Members.self)
                    }
                }
            }
    }
    

    /// - 모임 지우기
    func deleteMeeting(deletedMeeting: Meeting){
        Task{
            do{
                /// Delete Firestore Document
                guard let meetingID = deletedMeeting.id else{return}
                try await db.collection(strMeetings).document(meetingID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    /// - 모임 수정하기
    func updateMeeting(editMeeting: Meeting, title: String, description: String){
        Task{
            do{
                /// Delete Firestore Document
                guard let meetingID = editMeeting.id else{return}
                
                if title != editMeeting.title {
                    try await
                    db.collection(strMeetings).document(meetingID).updateData(["title": title])
                    print("title 수정")
                }
                
                if description != editMeeting.description {
                    try await
                    db.collection(strMeetings).document(meetingID).updateData(["description": description])
                    print("description 수정")
                }
                
                //                Firestore.firestore().collection("Meetings").document(meetingID).getDocument(as: Meeting.self) { result in
                //                    switch result {
                //                    case .success(let meet):
                //                        self.meeting = meet
                //
                //                    case .failure(let err):
                //                        print("updateMeeting에러: \(err)")
                //                    }
                //                }
                //
                //                print(meeting)
                //                await MainActor.run(body: {
                //                    meeting = meeting
                //                })
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    ///채팅구현
    func messagesListner(meetingId: String) {
        docListner = db.collection(strMeetings).document(meetingId).collection(strMessage)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                self.messages = documents.compactMap { queryDocumentSnapshot -> ChatMessage? in
                    let data = queryDocumentSnapshot.data()
                    let id = queryDocumentSnapshot.documentID
                    let text = data["text"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let userName = data["userName"] as? String ?? ""
                    let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
                    
                    return ChatMessage(id: id, text: text, userId: userId, userName: userName, timestamp: timestamp)
                }
            }
    }
    
    func sendMessage(meetingId: String, text: String, userId: String, userName: String) {
        db.collection(strMeetings).document(meetingId).collection(strMessage).addDocument(data: [
            "text": text,
            "userId": userId,
            "userName": userName,
            "timestamp": Timestamp()
        ])
    }
    
    /// 에러처리
    func handleError(error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

